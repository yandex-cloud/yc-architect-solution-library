using Google.Protobuf;
using Google.Protobuf.Collections;
using Grpc.Core;
using Grpc.Net.Client;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using Yandex.Cloud.Ai.Vision.V1;
using vision.batch.classifier;
using Newtonsoft.Json.Linq;

namespace vision.batch
{
    internal class VisionClassifier
    {

        private VisionService.VisionServiceClient visionClassifierClient;
        
        private static Uri endpointAddress = new Uri("https://vision.api.cloud.yandex.net:443");

        private Configuration config;
        private const int MAX_BATCH_SIZE = 8; // See https://cloud.yandex.ru/docs/vision/api-ref/grpc/vision_service#BatchAnalyze

        public VisionClassifier(Configuration config, ILoggerFactory loggerFactory)          
        {
            this.config = config;

            SslCredentials sslCred = new Grpc.Core.SslCredentials();
            var chn = GrpcChannel.ForAddress(endpointAddress, new GrpcChannelOptions { LoggerFactory = loggerFactory });
            visionClassifierClient = new VisionService.VisionServiceClient(chn);
        }

        internal void Classify(ClassifyTaskModel[] tasks)
        {

            var batches = tasks.Batch(MAX_BATCH_SIZE);
            foreach (var batch in batches)
            {
                // batch now has MAX_BATCH_SIZE items to work with

                if (tasks == null || tasks.Length == 0 || tasks.Length > 8)
                {
                    throw new ArgumentException($"Illegal arguments count in batch. min is 1 max is 8");
                }
                BatchAnalyzeRequest analyzeRequest = new BatchAnalyzeRequest()
                {
                    FolderId = config.folderId
                };
                foreach (ClassifyTaskModel t in tasks)
                {
                    analyzeRequest.AnalyzeSpecs.Add(makeAnalyzeSpec(t));
                }

                var call = visionClassifierClient.BatchAnalyzeAsync(
                    request: analyzeRequest,
                    headers: MakeMetadata(),
                    deadline: DateTime.UtcNow.AddMinutes(5)
                   ).GetAwaiter().GetResult();

                dynamic taskResponse = JObject.Parse(call.ToString());
            }
        }


        private AnalyzeSpec makeAnalyzeSpec(ClassifyTaskModel task)
        {

            AnalyzeSpec spec = new AnalyzeSpec()
            {
                 
                Content = task.ContentBinaryString,
                MimeType = task.MimeType
            };

            spec.Features.Add(new Feature { Type = Feature.Types.Type.Classification, ClassificationConfig = new FeatureClassificationConfig { Model = config.model} });

            return spec;
        }


        private Metadata MakeMetadata()
        {
            Metadata serviceMetadata = new Metadata();
            serviceMetadata.Add("authorization", $"Bearer {config.iamToken}");
            serviceMetadata.Add("x-data-logging-enabled", "true"); // 

            String requestId = Guid.NewGuid().ToString();

            serviceMetadata.Add("x-client-request-id", requestId); /* уникальный идентификатор запроса. Рекомендуем использовать UUID. 
            Сообщите этот идентификатор технической поддержке, чтобы мы смогли найти конкретрный запрос в системе и помочь вам.*/
           Console.WriteLine($"Metadata configured for request: {requestId}");
            return serviceMetadata;
        }
    }
}
