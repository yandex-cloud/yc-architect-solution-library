using Grpc.Core;
using Grpc.Net.Client;
using Microsoft.Extensions.Logging;
using Serilog;
using System;
using Microsoft.Extensions.DependencyInjection;
using Newtonsoft.Json.Linq;

namespace YC.SpeechKit.Streaming.Asr.SpeechKitClient
{
    public abstract class SpeechKitAbstractClient
    {

        protected Serilog.ILogger log;

        protected Uri endpointAddress;
        protected String Token;
        protected AuthTokenType tokenType;


        protected String AuthrozationHeaderValue{
            get
            {
                switch (this.tokenType) {
                    case AuthTokenType.IAM:
                         return $"Bearer {Token}";
                    case AuthTokenType.APIKey:
                         return $"Api-Key {Token}";
                    default:
                        throw new ArgumentException($"Speechkit Auth tokenType value illegal or empty");
                }
            }
        }

        protected SpeechKitAbstractClient(Uri address,  AuthTokenType tokenType, string Token)
        {
            this.log = Log.Logger;
            this.endpointAddress = address;
            this.Token = Token;
            this.tokenType = tokenType;
        }


        protected GrpcChannel MakeChannel(ILoggerFactory loggerFactory)
        {

           // ILoggerFactory loggerFactory = Program.serviceProvider.GetService<ILoggerFactory>();

            return GrpcChannel.ForAddress(this.endpointAddress,  new GrpcChannelOptions { LoggerFactory = loggerFactory });
        }

        protected Metadata MakeMetadata()
        {
            Metadata serviceMetadata = new Metadata();
            serviceMetadata.Add("authorization", AuthrozationHeaderValue);
            serviceMetadata.Add("x-data-logging-enabled", "true"); // 

            String requestId = Guid.NewGuid().ToString();

            serviceMetadata.Add("x-client-request-id", requestId); /* уникальный идентификатор запроса. Рекомендуем использовать UUID. 
            Сообщите этот идентификатор технической поддержке, чтобы мы смогли найти конкретрный запрос в системе и помочь вам.*/
            log.Information($"Metadata configured for request: {requestId}");
            return serviceMetadata;
        }
    }
}
