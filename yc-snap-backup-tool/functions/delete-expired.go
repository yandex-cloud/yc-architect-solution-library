package main

import (
	"context"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/yandex-cloud/go-genproto/yandex/cloud/compute/v1"
	ycsdk "github.com/yandex-cloud/go-sdk"
)

//goland:noinspection GoUnusedExportedFunction
func DeleteHandler(ctx context.Context) (*Response, error) {
	folderId := os.Getenv("FOLDER_ID")
	// Авторизация в SDK при помощи сервисного аккаунта
	sdk, err := ycsdk.Build(ctx, ycsdk.Config{
		// Вызов InstanceServiceAccount автоматически запрашивает IAM-токен и формирует
		// при помощи него данные для авторизации в SDK
		Credentials: ycsdk.InstanceServiceAccount(),
	})
	if err != nil {
		return nil, err
	}

	// Получаем итератор снепшотов при помощи YC SDK
	iterReq := &compute.ListSnapshotsRequest{
		FolderId: folderId,
	}
	snapshotIter := sdk.Compute().Snapshot().SnapshotIterator(ctx, iterReq)
	deletedIds := []string{}
	// Итрерируемся по нему
	for snapshotIter.Next() {
		snapshot := snapshotIter.Value()
		labels := snapshot.Labels
		if labels == nil {
			continue
		}
		// Проверяем есть ли у снепшота лейбл `expiration_ts`.
		expirationTsVal, ok := labels["expiration_ts"]
		if !ok {
			continue
		}
		now := time.Now()
		expirationTs, err := strconv.Atoi(expirationTsVal)
		if err != nil {
			continue
		}

		// Если он есть и время сейчас больше, чем то что записано в лейбл, то удаляем снепшот.
		if int(now.Unix()) > expirationTs {
			op, err := sdk.WrapOperation(sdk.Compute().Snapshot().Delete(ctx, &compute.DeleteSnapshotRequest{
				SnapshotId: snapshot.Id,
			}))
			if err != nil {
				return nil, err
			}
			meta, err := op.Metadata()
			if err != nil {
				return nil, err
			}
			deletedIds = append(deletedIds, meta.(*compute.DeleteSnapshotMetadata).GetSnapshotId())
		}
	}

	return &Response{
		StatusCode: 200,
		Body:       fmt.Sprintf("Deleted expired snapshots: %s", strings.Join(deletedIds, ", ")),
	}, nil
}
