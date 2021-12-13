using Amazon.S3;
using Amazon.S3.Model;
using System.Linq;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using System.Net;

namespace SkBatchAsrClient
{


    class S3Client : IS3Client
    {

        private readonly IAmazonS3 yandexS3;
        internal const string PROPERTY_FILE_NAME = "X-Amz-Meta-FileName";
        internal const string PROPERTY_CONTENT_TYPE = "X-Amz-Meta-ContentType";
        private ILogger log;

        public S3Client(IAmazonS3 yandexS3, ILoggerFactory _loggerFactory)
        {
            this.yandexS3 = yandexS3;
            log = _loggerFactory.CreateLogger<IS3Client>();            
        }

        public void ProcessBucket(string bucket, SkRecognitionClient recognitionClient)
        {

            ListObjectsV2Request req = new ListObjectsV2Request
                {
                    BucketName = bucket,
                };



            try
             {
                ListObjectsV2Response response = null;
                do
                {
                    response = yandexS3.ListObjectsV2Async(req).GetAwaiter().GetResult();

                    if (response.HttpStatusCode != HttpStatusCode.OK)
                    {
                        log.LogError($"HttpRequest error {response.HttpStatusCode}");
                    }

                    var qResponse = response.S3Objects.AsQueryable<S3Object>();
                    var retVal = from key in qResponse
                                 where key.Key.EndsWith(".wav") || key.Key.EndsWith(".ogg")
                                 orderby key.Key
                                 select new SkTaskModel
                                 {
                                     AudioUrl = yandexS3.GeneratePreSignedURL(bucket, key.Key, DateTime.Now.AddHours(24), null),
                                     Path = key.Key,
                                     TaskId = null
                                 };                    

                    // Set the marker property
                    req.ContinuationToken = response.NextContinuationToken;

                    recognitionClient.CreateRecognitionTask(retVal.ToArray<SkTaskModel>());

                } while (response != null && response.IsTruncated); 

            }
            catch(Exception ex)
            {
                log.LogError(ex, "GetObjectList execution error");
            };
           
        }

    }


    public interface IS3Client
    {
        void ProcessBucket(string bucket, SkRecognitionClient recognitionClient);        
    }
}
