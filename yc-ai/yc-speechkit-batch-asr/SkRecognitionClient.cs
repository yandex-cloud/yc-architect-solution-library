using Google.Protobuf;
using Grpc.Core;
using Grpc.Net.Client;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using Yandex.Cloud.Ai.Stt.V2;
using Newtonsoft.Json.Linq;

namespace SkBatchAsrClient
{
    public class SkRecognitionClient
    {
        private ILogger log;
        private ISkTaskDb taskDb;
        private Uri endpointAddress;
        private string IamToken;
        private RecognitionConfig rConf;
        private Configuration appConfig;
        private SttService.SttServiceClient speechKitRpctClient;

        public SkRecognitionClient(Uri address, Configuration cfg, RecognitionSpec rSpec, 
            ILoggerFactory loggerFactory, ISkTaskDb taskDb)
        {
            this.log = loggerFactory.CreateLogger<SkRecognitionClient>();
            this.taskDb = taskDb;
            this.endpointAddress = address;
            this.appConfig = cfg;

            this.rConf = new RecognitionConfig()
            {
                FolderId = cfg.folderId,
                Specification = rSpec
            };
          
            SslCredentials sslCred = new Grpc.Core.SslCredentials();
            var chn = GrpcChannel.ForAddress(endpointAddress, new GrpcChannelOptions { LoggerFactory = loggerFactory });

            speechKitRpctClient = new SttService.SttServiceClient(chn);

        }


        public void CreateRecognitionTask(SkTaskModel[] tasks)
        {
            foreach (SkTaskModel task in tasks) {
                if (!taskDb.Exist(task))
                {
                    LongRunningRecognitionRequest rR = new LongRunningRecognitionRequest();
                    rR.Audio = new RecognitionAudio
                    {
                        Uri = task.AudioUrl
                    };
                    rR.Config = this.rConf;

                    var call = this.speechKitRpctClient.LongRunningRecognize(
                        headers: MakeMetadata(),
                        deadline: DateTime.UtcNow.AddMinutes(5),
                        request: rR);

                    dynamic taskResponse = JObject.Parse(call.ToString());

                    task.TaskId = taskResponse.id;

                    taskDb.storeTask(task);
                    this.log.LogInformation($"Created task {task.TaskId} for url {task.AudioUrl}");
                }
            }
        }


        private Metadata MakeMetadata()
        {
            Metadata serviceMetadata = new Metadata();
            if (!string.IsNullOrEmpty(appConfig.iamToken))
            {
                serviceMetadata.Add("authorization", $"Bearer {appConfig.iamToken}");
            }else if (!string.IsNullOrEmpty(appConfig.apiKey))
            {
                serviceMetadata.Add("authorization", $"Api-Key {appConfig.apiKey}");
            }
            else
            {

            }
            serviceMetadata.Add("x-data-logging-enabled", "true"); // 

            String requestId = Guid.NewGuid().ToString();

            serviceMetadata.Add("x-client-request-id", requestId); /* уникальный идентификатор запроса. Рекомендуем использовать UUID. 
            Сообщите этот идентификатор технической поддержке, чтобы мы смогли найти конкретрный запрос в системе и помочь вам.*/
            log.LogInformation($"Metadata configured for request: {requestId}");
            return serviceMetadata;
        }

    }
}