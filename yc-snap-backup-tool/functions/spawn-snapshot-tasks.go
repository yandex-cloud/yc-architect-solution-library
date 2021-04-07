package main

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/yandex-cloud/go-genproto/yandex/cloud/compute/v1"
	"os"
	"strings"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sqs"
	ycsdk "github.com/yandex-cloud/go-sdk"
)

var (
	endpoint = "https://message-queue.api.cloud.yandex.net"
	region   = "ru-central1"
)

func constructDiskMessage(data CreateSnapshotParams, queueUrl *string) *sqs.SendMessageInput {
	body, _ := json.Marshal(&data)
	messageBody := string(body)
	return &sqs.SendMessageInput{
		MessageBody: &messageBody,
		QueueUrl:    queueUrl,
	}
}

//goland:noinspection GoUnusedExportedFunction
func SpawnHandler(ctx context.Context) (*Response, error) {
	folderId := os.Getenv("FOLDER_ID")
	mode := os.Getenv("MODE")
	queueUrl := os.Getenv("QUEUE_URL")
	onlyMarked := mode == "only-marked"

	sdk, err := ycsdk.Build(ctx, ycsdk.Config{
		// Вызов InstanceServiceAccount автоматически запрашивает IAM-токен и формирует
		// при помощи него данные для авторизации в SDK
		Credentials: ycsdk.InstanceServiceAccount(),
	})
	if err != nil {
		return nil, err
	}

	sess := session.Must(session.NewSessionWithOptions(session.Options{
		Config: aws.Config{
			Endpoint: &endpoint,
			Region:   &region,
		},
		SharedConfigState: session.SharedConfigEnable,
	}))

	svc := sqs.New(sess)

	// Получаем итератор
	iterReq := &compute.ListDisksRequest{
		FolderId: folderId,
	}
	discIter := sdk.Compute().Disk().DiskIterator(ctx, iterReq)
	var diskIds []string
	// И итерируемся по всем дискам в фолдере
	for discIter.Next() {
		d := discIter.Value()
		labels := d.GetLabels()
		ok := false
		if labels != nil {
			_, ok = labels["snapshot"]
		}
		// Если в переменной `MODE` указано `only-marked`, то снепшоты будут создаваться только для дисков,
		// у которых проставлен лейбл `snapshot`. Иначе снепшотиться будут все диски.
		if onlyMarked && !ok {
			continue
		}

		params := constructDiskMessage(CreateSnapshotParams{
			FolderId: folderId,
			DiskId:   d.Id,
		}, &queueUrl)
		// Отправляем в Yandex Message Queue сообщение с праметрами какой диск нужно снепшотить
		_, err = svc.SendMessage(params)
		if err != nil {
			fmt.Println("Error", err)
			return nil, err
		}
		diskIds = append(diskIds, d.Id)
	}
	return &Response{
		StatusCode: 200,
		Body:       strings.Join(diskIds, ", "),
	}, nil
}
