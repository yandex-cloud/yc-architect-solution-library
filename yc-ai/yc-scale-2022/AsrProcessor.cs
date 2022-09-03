using Serilog;
using System;
using System.Threading;
using System.Threading.Tasks;
using YC.SpeechKit.Streaming.Asr;
using YC.SpeechKit.Streaming.Asr.SpeechKitClient;
using System.Linq;
using yc_scale_2022.Models;
using Yandex.Cloud.Ai.Stt.V2;
using System.Text;
using System.Net.WebSockets;
using System.Net.Http.Headers;
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
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace yc_scale_2022
{
    public class AsrProcessor : IDisposable
    {
        private Mutex callMutex = new Mutex(false, "callLock");
        private int bytesSent = 0;
        private const int MAX_BYTES_SENT = 10 * 1024 * 1024; // check https://cloud.yandex.com/docs/speechkit/stt/streaming#session-restrictions for limitation details


        private AsrSession asrSession = new AsrSession();

        private RecognitionSpec rSpeс;
        private ILogger logger;
        private ILoggerFactory _loggerFactory;
        private IConfiguration configuration;
        private WebSocket webSocket;
        SpeechKitSttStreamClient speechKitClient;
        ApplicationDbContext dbConn;
        
        Object db_changes_locker = 0;
        bool request_in_progress = false;

        /* Last SpeechKit Partial (not final) Response identity*/
        private Guid lastPartialResponseId = Guid.Empty;

        public AsrProcessor(AudioStreamFormat format, IConfiguration configuration)
        {
            


            this._loggerFactory = LoggerFactory.Create(builder =>
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



        public SpeechKitSttStreamClient Init(HttpContext context, WebSocket webSocket)
        {

            this.webSocket = webSocket;

            this.dbConn = new ApplicationDbContext(this.configuration);

            this.asrSession.TraceIdentifier = context.TraceIdentifier;
            this.asrSession.UserAgent = context.Request.Headers["User-Agent"];
            this.asrSession.RemoteIpAddress = context.Connection.RemoteIpAddress.ToString();
            
                        

            speechKitClient =  new SpeechKitSttStreamClient(new Uri("https://stt.api.cloud.yandex.net:443"),
                                                    
                                                    this.configuration["FolderId"],
                                                    (AuthTokenType) Enum.Parse(typeof(AuthTokenType), this.configuration["AuthTokenType"]),
                                                    this.configuration["Token"],
                                                this.rSpeс, this._loggerFactory);//
                // Subscribe for speech to text events comming from SpeechKit
            SpeechToTextResponseReader.ChunkRecived += this.SpeechToTextResponseReader_ChunksRecived;
            lock (db_changes_locker)
            {
                this.dbConn.AsrSessions.Add(this.asrSession);
                this.dbConn.SaveChanges();
            }
            logger.LogInformation($"session {asrSession.AsrSessionId} started.");
            return speechKitClient;
        }

        private  async void SpeechToTextResponseReader_ChunksRecived(object sender, ChunkRecievedEventArgs e)
        {
            try
            {
                request_in_progress = true;
                if (webSocket.State == WebSocketState.Closed)
                    return; //Don't preocess events from closed sessions

                String jSonRes = e.AsJson(false);

                // Send response to WebSocket
                await this.ResponseToBrowser(jSonRes);


                SpeechKitResponseModel responseModel = mapResponseJson(jSonRes);

                this.dbConn.AsrResponses.Add(responseModel);


                if (responseModel.Final) { 
                    // apply sentiment detection
                    await this.SentimentAnalysis(responseModel);
                    
                    this.lastPartialResponseId = Guid.Empty;
                }
                else
                {
                    this.lastPartialResponseId = responseModel.RecognitionId;
                    logger.LogTrace($"Skip partial results {responseModel.RecognitionId}");
                }

                
            }catch(Exception ex)
            {
                logger.LogError($"Error {ex.Message} \n {ex.StackTrace} \n processing database updated from session {asrSession.AsrSessionId}");
            }
            finally
            {
                request_in_progress = false;
            }
        }

        private SpeechKitResponseModel mapResponseJson(String asrJson)
        {
            // Map response data 
            SpeechKitResponseModel responseModel = JsonSerializer.Deserialize<SpeechKitResponseModel>(asrJson);
            responseModel.SessionId = this.asrSession.AsrSessionId;

            /* Store response into database */
            foreach (Alternative alt in responseModel.Alternatives)
            {
                alt.RecognitionId = responseModel.RecognitionId;
                foreach (RecognizedWord w in alt.Words)
                    w.AlternativeId = alt.AlternativeId;
            }

            return responseModel;
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
                logger.LogTrace($"session {asrSession.AsrSessionId} successfullty sent to websocket.");
                return 1;
            }
            else
            {
                logger.LogWarning($"session {asrSession.AsrSessionId} websocket {webSocket.State}.");
                return 0;
            }
            
        }

        private async Task<SpeechKitResponseModel> SentimentAnalysis(SpeechKitResponseModel responseModel)
        {

            if (responseModel.Alternatives != null && responseModel.Alternatives.Count > 0)
            {
                    HttpClient _httpClient = new HttpClient();
                    StringBuilder sb = new StringBuilder(); 
                    foreach (Alternative alt in responseModel.Alternatives){
                       sb.AppendLine(alt.Text);
                    }
                    MlInput mlInTextPayload = new MlInput() {  
                        input_data  = new MlInputTextPayload() { text = sb.ToString()} 
                    };
                   // string mlInJsonPayload = JsonSerializer.Serialize(mlInTextPayload);

                    String node_id = this.configuration["MlNodeId"]; // datashpere node id
                    String ml_api_key = this.configuration["MlApiKey"]; // datashpere api key
                   
  
                    String url = $"https://datasphere.api.cloud.yandex.net/datasphere/v1/nodes/{node_id}:execute";
                    
                    _httpClient.DefaultRequestHeaders.Add("Host", "datasphere.api.cloud.yandex.net");
                    _httpClient.DefaultRequestHeaders.Authorization = 
                                        new System.Net.Http.Headers.AuthenticationHeaderValue("Api-Key",ml_api_key);

                MlInputModelPayload mlPayload = new MlInputModelPayload() { 
                                folder_id= this.configuration["MlFolderId"], ///datashpere folder id
                         input = mlInTextPayload
                };

                    HttpResponseMessage httpResponse = await _httpClient.PostAsync(url, 
                                        new StringContent(JsonSerializer.Serialize(mlPayload), Encoding.UTF8, "application/json"));
                    if (httpResponse.StatusCode == System.Net.HttpStatusCode.OK)
                    {
                        String respJsonPayLoad = await httpResponse.Content.ReadAsStringAsync();

                        try
                        {
                        InferenceRoot mlOutput = JsonSerializer.Deserialize<InferenceRoot>(respJsonPayLoad);

                            mlOutput.output.voice_stat.emotions_list.recognition_id = responseModel.RecognitionId;
                            this.dbConn.MlInferences.Add(mlOutput.output.voice_stat.emotions_list);
                            logger.LogInformation($"session {asrSession.AsrSessionId}  model inference recieved for asr response {responseModel.RecognitionId}..");

                        }
                        catch(Exception e)
                        {
                            logger.LogError($"Error parsing rest {url} response {e} for asr response {responseModel.RecognitionId}.");                           
                        }
                    }
                    else
                    {
                        logger.LogError($"Http error {httpResponse.StatusCode} calling {url} for asr response {responseModel.RecognitionId}..");
                        
                    }
            }

            // Attempt saving changes into to the database
            lock (db_changes_locker)
            {                
                int savedEntitiesCount = this.dbConn.SaveChanges();
                logger.LogInformation($"db updated with {savedEntitiesCount} entities for {responseModel.RecognitionId} session {asrSession.AsrSessionId}");

            }
            return responseModel;
        }

        /* Handle last partial results as final before close */
        internal async Task<SpeechKitResponseModel> SafePartialResults()
        {
                SpeechKitResponseModel responseModel = this.dbConn.AsrResponses.Find(this.lastPartialResponseId);
            if (responseModel != null)
            {
                logger.LogInformation($"Mark last partial result {this.lastPartialResponseId} as final for session {asrSession.AsrSessionId}.");
                responseModel.Final = true;
                return await SentimentAnalysis(responseModel);
            }
            else
            {
                return null;
            }
        }

        public void Dispose()
        {
            try
            {
                // TODO: Wait tasks to compleate
                if (this.speechKitClient != null)
                {
                    logger.LogInformation($"Shutting down session {asrSession.AsrSessionId} resources.");
                    while (request_in_progress)
                    {
                        logger.LogInformation($"Waiting 500ms current thread to compleate.");
                        Thread.Sleep(1000);
                    }


                    if (this.dbConn != null)
                    {

                        this.dbConn.Dispose();
                        this.dbConn = null;
                        logger.LogTrace($"Database connection for session {asrSession.AsrSessionId} closed.");
                    }


                    // dispose speechkit client
                    this.speechKitClient.Dispose();
                    this.speechKitClient = null;
                    logger.LogInformation($"session {asrSession.AsrSessionId} closed.");
                }
            }catch(Exception ex)
            {
                logger.LogError($"Error {ex.Message} during shutting down session {asrSession.AsrSessionId} ");
            }
            
        }
    }
}
