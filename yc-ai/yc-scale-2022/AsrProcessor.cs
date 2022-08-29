using Serilog;
using System;
using System.Threading;
using System.Threading.Tasks;
using YC.SpeechKit.Streaming.Asr;
using YC.SpeechKit.Streaming.Asr.SpeechKitClient;
using yc_scale_2022.Models;
using Yandex.Cloud.Ai.Stt.V2;
using System.Text;
using System.Net.WebSockets;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using yc_scale_2022.Controllers;
using ILogger = Microsoft.Extensions.Logging.ILogger;
using System.Text.Json;
using System.Collections.Generic;
using System.Net.Http;
using System.Security.Policy;
using YamlDotNet.Core.Tokens;
using Microsoft.AspNetCore.Mvc;

namespace yc_scale_2022
{
    public class AsrProcessor : IDisposable
    {
        private Mutex callMutex = new Mutex(false, "callLock");
        private int bytesSent = 0;
        private const int MAX_BYTES_SENT = 10 * 1024 * 1024; // check https://cloud.yandex.com/docs/speechkit/stt/streaming#session-restrictions for limitation details


        private Guid AsrSessionId = Guid.NewGuid();

        private RecognitionSpec rSpeс;
        private ILogger logger;
        private ILoggerFactory _loggerFactory;
        private IConfiguration configuration;
        private WebSocket webSocket;
        SpeechKitSttStreamClient speechKitClient;
        SpeechKitAsrController controller;

        public AsrProcessor(AudioStreamFormat format, IConfiguration configuration)
        {
           
            ILoggerFactory _loggerFactory = LoggerFactory.Create(builder =>
            {
                builder.AddConsole();
                builder.AddDebug();
            });
            this.logger = _loggerFactory.CreateLogger<AsrProcessor>();

            this.rSpeс = new RecognitionSpec()
            {
                LanguageCode = format.language,
                ProfanityFilter = false,
                Model = "general",
                PartialResults = true, //возвращать только финальные результаты false
                AudioEncoding = (RecognitionSpec.Types.AudioEncoding)Enum.Parse(typeof(RecognitionSpec.Types.AudioEncoding), 
                                                format.getAudioEncoding()),
                SampleRateHertz = format.sampleRate
            };
            
            this.configuration = configuration;
        }



        public void Init(SpeechKitAsrController controller, WebSocket webSocket)
        {

            this.webSocket = webSocket;
            this.controller = controller;
            speechKitClient =  new SpeechKitSttStreamClient(new Uri("https://stt.api.cloud.yandex.net:443"),
                                                    
                                                    this.configuration["FolderId"],
                                                    (AuthTokenType) Enum.Parse(typeof(AuthTokenType), this.configuration["AuthTokenType"]),
                                                    this.configuration["Token"],
                                                this.rSpeс, this._loggerFactory);//
                                                                       // Subscribe for speech to text events comming from SpeechKit
            SpeechToTextResponseReader.ChunkRecived += this.SpeechToTextResponseReader_ChunksRecived;

            controller.AudioBinaryRecived += speechKitClient.Listener_SpeechKitSend;
            logger.LogInformation($"session {AsrSessionId} started.");
        }

        private  void SpeechToTextResponseReader_ChunksRecived(object sender, ChunkRecievedEventArgs e)
        {
            if (webSocket.State == WebSocketState.Closed)
                return; //Don't preocess events from closed sessions

            String jSonRes = e.AsJson(false);
            new Task(async () =>
            {
                // Web Socket response
                await this.ResponseToBrowser(jSonRes);
            }).Start();

            new Task(async () =>
            {
                await this.SentimentAnalysis(jSonRes);
            }).Start();

        }

        private async Task<byte> ResponseToBrowser(String asrJson)
        {
            if (webSocket.State == WebSocketState.Open)
            {
           
                asrJson = "{ \"Chunks\": [" + asrJson + "]}";
                
                WssPayload wpl = new WssPayload() { type = WssPayload.MSG_TYPE_DATA, data = asrJson };
                string jsonReplay = JsonSerializer.Serialize(wpl);
                byte[] bytePayload = Encoding.UTF8.GetBytes(jsonReplay);
                await webSocket.SendAsync(new ArraySegment<byte>(bytePayload, 0, bytePayload.Length),
                                WebSocketMessageType.Text, true, CancellationToken.None);
                return 1;
            }
            else
            {
                logger.LogWarning($"session {AsrSessionId} websocket {webSocket.State}.");
                return 0;
            }
            
        }

        private async Task<byte> SentimentAnalysis(String asrJson)
        {
            SpeechKitResponseModel responseModel = JsonSerializer.Deserialize<SpeechKitResponseModel>(asrJson);
            

            if (responseModel.Final && responseModel.Alternatives != null && responseModel.Alternatives.Count > 0)
            {
                    HttpClient _httpClient = new HttpClient();
                    StringBuilder sb = new StringBuilder(); 
                    foreach (Alternative alt in responseModel.Alternatives){
                        sb.AppendLine(alt.Text);
                    }
                    MlInputTextPayload mlInTextPayload = new MlInputTextPayload() { text = sb.ToString() };
                    string mlInJsonPayload = JsonSerializer.Serialize(mlInTextPayload);

                    String node_id = this.configuration["MlNodeId"]; // datashpere node id
                    String ml_api_key = this.configuration["MlApiKey"]; // datashpere api key
                   
  
                    String url = $"https://datasphere.api.cloud.yandex.net/datasphere/v1/nodes/{node_id}:execute";
                    
                    _httpClient.DefaultRequestHeaders.Add("Host", "datasphere.api.cloud.yandex.net");
                    //_httpClient.DefaultRequestHeaders.Add("Accept", "application/json");
                    //_httpClient.DefaultRequestHeaders.Add("Content-Type", "application/json");
                    _httpClient.DefaultRequestHeaders.Authorization = 
                                        new System.Net.Http.Headers.AuthenticationHeaderValue("Api-Key",ml_api_key);

                    MlModelPayload mlPayload = new MlModelPayload() { node_id = node_id, 
                                folder_id= this.configuration["MlFolderId"], ///datashpere folder id
                        data = mlInJsonPayload
                    };

                    HttpResponseMessage httpResponse = await _httpClient.PostAsync(url, 
                                        new StringContent(JsonSerializer.Serialize(mlPayload), Encoding.UTF8, "application/json"));
                    if (httpResponse.StatusCode == System.Net.HttpStatusCode.OK)
                    {
                        String respJsonPayLoad = await httpResponse.Content.ReadAsStringAsync();

                        try
                        {
                            MlResponsePayload emotions = JsonSerializer.Deserialize<MlResponsePayload>(respJsonPayLoad);
                        }catch(Exception e)
                        {
                            logger.LogError($"Error parsing rest {url} response {e}.");
                            return 0;
                        }
                    }
                    else
                    {
                        logger.LogError($"Http error {httpResponse.StatusCode} calling {url}.");
                        return 0;
                    }


                return 1;
            }
            else
            {
                logger.LogTrace( $"Skip partial results^ {asrJson}");
                return 0;
            }
        }

            public void Dispose()
        {
            
            // TODO: Wait tasks to compleate
            if (this.speechKitClient != null)            
            {
                logger.LogInformation($"Shutting down session {AsrSessionId} resources.");
                // remove event handler
                this.controller.AudioBinaryRecived -= speechKitClient.Listener_SpeechKitSend;
                // dispose speechkit client
                this.speechKitClient.Dispose();
                this.speechKitClient = null;
                logger.LogInformation($"session {AsrSessionId} closed.");
            }
            
        }
    }
}
