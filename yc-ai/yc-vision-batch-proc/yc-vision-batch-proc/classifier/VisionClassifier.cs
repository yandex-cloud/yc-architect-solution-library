using Google.Protobuf;
using Google.Protobuf.Collections;
using Grpc.Core;
using Grpc.Net.Client;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Text;
using Yandex.Cloud.Ai.Vision.V1;
using vision.batch.classifier;
using Newtonsoft.Json.Linq;

namespace vision.batch
{
    internal class VisionClassifier
    {
        private ILogger log;
        private VisionService.VisionServiceClient visionClassifierClient;
        
        private static Uri endpointAddress = new Uri("https://vision.api.cloud.yandex.net:443");

        private Configuration config;
        private const int MAX_BATCH_SIZE = 5; // See https://cloud.yandex.ru/docs/vision/api-ref/grpc/vision_service#BatchAnalyze

        private DirectoryInfo outDirectory;

        public VisionClassifier(Configuration config, ILoggerFactory loggerFactory)          
        {
            this.config = config;
            this.log = loggerFactory.CreateLogger<VisionClassifier>();
            SslCredentials sslCred = new Grpc.Core.SslCredentials();
            var chn = GrpcChannel.ForAddress(endpointAddress, new GrpcChannelOptions { LoggerFactory = loggerFactory });
            visionClassifierClient = new VisionService.VisionServiceClient(chn);

            String outDirectoryPath = Path.Combine(AppContext.BaseDirectory, ClassifyTaskHelper.GetTimestamp(DateTime.Now));
            this.outDirectory = Directory.CreateDirectory(outDirectoryPath);
            this.log.LogInformation($"output directory created: {outDirectoryPath}");
        }

        internal void Classify(ClassifyTaskModel[] tasks)
        {
            if (tasks == null || tasks.Length == 0)
            {
                this.log.LogWarning($"No images to process");
                return;
            }
            var batches = tasks.Batch(MAX_BATCH_SIZE);
            if (batches == null)
            {
                this.log.LogError($"Batch splitting error");
                return;
            }
            foreach (var batch in batches)
            {
                // batch now has MAX_BATCH_SIZE items to work with

                /*  if (batch == null)
                  {
                      throw new ArgumentException($"Illegal arguments count in batch. min is 1 max is 8");
                  }*/
                dynamic taskResponse;
                bool isErr = true;
                do
                {
                    BatchAnalyzeRequest analyzeRequest = new BatchAnalyzeRequest()
                    {
                        FolderId = config.folderId
                    };
                    foreach (ClassifyTaskModel t in batch)
                    {
                        analyzeRequest.AnalyzeSpecs.Add(makeAnalyzeSpec(t));
                    }

                   var call  = visionClassifierClient.BatchAnalyzeAsync(
                        request: analyzeRequest,
                        headers: MakeMetadata(),
                        deadline: DateTime.UtcNow.AddMinutes(5)
                       ).GetAwaiter().GetResult();

                    taskResponse = JObject.Parse(call.ToString());

                    isErr = isError(taskResponse);
                    if (isErr)
                    {
                        this.log.LogInformation($"Quota exceeded waiting 5 sec.");
                        Thread.Sleep(5 * 1000);
                    }

                } while (isErr);

                safeResults(batch, taskResponse);
                                
            }
        }


        private void safeResults(IEnumerable<ClassifyTaskModel> tasks, dynamic taskResponse)
        {
            JArray parseResponse = (JArray)taskResponse.results;
            int i = 0;
            foreach (ClassifyTaskModel t in tasks)
            {
                String jsonResult = parseResponse[i].ToString();
                String outJsonPath = Path.Combine(outDirectory.FullName, Path.GetFileName(t.ImagePath) + ".json");

                File.WriteAllText(outJsonPath, jsonResult);
                this.log.LogInformation($"image: {t.ImagePath} compleated.");
                this.log.LogTrace($"result:\n  {jsonResult}");
                i++;
            }
        }

        private bool isError(dynamic taskResponse)
        {
            JArray parseResponse = (JArray)taskResponse.results;
            

            return parseResponse.ToString().Contains("limit on requests was exceeded", StringComparison.InvariantCultureIgnoreCase);
        }

        private AnalyzeSpec makeAnalyzeSpec(ClassifyTaskModel task)
        {

            AnalyzeSpec spec = new AnalyzeSpec()
            {
                 
                Content = task.ContentBinaryString,
                MimeType = task.MimeType
            };

            switch (config.mode)
            {
                case Mode.CLASSIFICATION:
                    spec.Features.Add(new Feature { Type = Feature.Types.Type.Classification, ClassificationConfig = new FeatureClassificationConfig { Model = config.model } });
                    break;
                case Mode.IMAGE_COPY_SEARCH:
                    spec.Features.Add(new Feature { Type = Feature.Types.Type.ImageCopySearch});
                    break;
                default:
                    throw new ArgumentException($"Unknow operation model {config.mode}");

            }


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
