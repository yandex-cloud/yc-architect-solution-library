using Google.Protobuf;
using Google.Protobuf.Collections;
using Grpc.Core;
using Grpc.Net.Client;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using Yandex.Cloud.Ai.Vision.V2;
using vision.batch.classifier;
using static Yandex.Cloud.Ai.Vision.V2.ImageClassifierService;

namespace vision.batch.classifier
{
    /*
     
     Классификация изображений https://cloud.yandex.ru/docs/vision/api-ref/grpc/
     */
    internal class ImageClassifier
    {

        private ImageClassifierServiceClient visionClassifierClient;
        private Uri endpointAddress;
        private string IamToken;
        private string folderId;

        public ImageClassifier(Uri address, string folderId, string IamToken, ILoggerFactory loggerFactory)
        {
            this.endpointAddress = address;
            this.IamToken = IamToken;

            SslCredentials sslCred = new Grpc.Core.SslCredentials();
            var chn = GrpcChannel.ForAddress(endpointAddress, new GrpcChannelOptions { LoggerFactory = loggerFactory });
            visionClassifierClient = new ImageClassifierService.ImageClassifierServiceClient(chn);
        }

        internal async void CreateClassifyRequest(ClassifyTaskModel[] tasks)
        {
            if (tasks == null || tasks.Length == 0 || tasks.Length > 8)
            {
                throw new ArgumentException($"Illegal arguments count in batch. min is 1 max is 8");
            }



            foreach (ClassifyTaskModel t in tasks)
            {
                Image img = new Image()
                {
                   // ImageType = Enum.Parse(Image.Types.ImageType, t.ImageType)
                };

                AnnotationRequest analyzeRequest = new AnnotationRequest()
                {
                    Image = img
                };

                // analyzeRequest.AnalyzeSpecs.Add(makeAnalyzeSpec(t));
            }

            /*var call = await visionRpctClient.BatchAnalyzeAsync(
                request: analyzeRequest,
                headers: MakeMetadata(),
                deadline: DateTime.UtcNow.AddMinutes(5)
               );*/

        }


    }
}
