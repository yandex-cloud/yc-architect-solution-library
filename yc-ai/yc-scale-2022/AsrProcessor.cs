using Serilog;
using System;
using System.Threading;
using System.Threading.Tasks;
using ai.adoptionpack.speechkit.hybrid;
using ai.adoptionpack.speechkit.hybrid.client;
using System.Linq;

// using Speechkit.Stt.V3;
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
using Speechkit.Stt.V3;
using Alternative = yc_scale_2022.Models.V3SpeechKitModels.Alternative;
using SpeechKitResponseModel = yc_scale_2022.Models.V3SpeechKitModels.SpeechKitResponseModel;
using Word = yc_scale_2022.Models.V3SpeechKitModels.Word;
using yc_scale_2022.Models;
using Microsoft.EntityFrameworkCore.Internal;

namespace yc_scale_2022
{
    public class AsrProcessor : IDisposable
    {
        private Mutex callMutex = new Mutex(false, "callLock");
        
        private const int MAX_BYTES_SENT = 10 * 1024 * 1024; // check https://cloud.yandex.com/docs/speechkit/stt/streaming#session-restrictions for limitation details


        private AsrSession asrSession;

        private Options args;
        private ILogger logger;
        private ILoggerFactory _loggerFactory;
        private IConfiguration configuration;

        private WebSocket webSocket;
        SpeechKitSttStreamClient speechKitClient;

        ApplicationDbContext dbConn;

        MlProcessor mlInference;
        TrackerProcessor trackProcessor;

        private static Dictionary<string, string> substDictionary = null;
       
        Object db_changes_locker = 0;
        bool request_in_progress = false;

        /* Last SpeechKit Partial (not final) Response identity*/
        private Guid lastPartialResponseId = Guid.Empty;

        private SpeechKitResponseModel finalRefinement;
        private StringBuilder WholeRefinementText;

        private SpeechKitResponseModel final;
        private StringBuilder WholeFinalText;


        public AsrProcessor(AudioStreamFormat format, IConfiguration configuration)
        {

            this._loggerFactory = LoggerFactory.Create(builder =>
            {
                builder.AddConsole();
                builder.AddDebug();
            });
            this.logger = _loggerFactory.CreateLogger<AsrProcessor>();
            this.configuration = configuration;
            this.args = new Options()
            {
                Token = configuration["Token"],
                TokenType = (AuthTokenType)Enum.Parse(typeof(AuthTokenType), configuration["AuthTokenType"]),
                lang = format.language,                 
                model = "general:rc",
                /*ProfanityFilter = false,
                PartialResults = true, //возвращать только финальные результаты false
                audioEncoding = (ContainerAudio.Types.ContainerAudioType)Enum.Parse(typeof(ContainerAudio.Types.ContainerAudioType), 
                                                format.getAudioEncoding()),*/

                sampleRate = format.sampleRate
            };
            WholeFinalText = WholeRefinementText = new StringBuilder();
            final = finalRefinement = null;

            if (!string.IsNullOrEmpty(this.configuration["MlApiKey"]))
            {
                this.mlInference = new MlProcessor(configuration, _loggerFactory.CreateLogger<MlProcessor>());

                if (!string.IsNullOrEmpty(configuration["TrackerOAuth"]) && !string.IsNullOrEmpty(configuration["X-Org-ID"]))
                {
                    this.trackProcessor = new TrackerProcessor(configuration, _loggerFactory.CreateLogger<TrackerProcessor>());
                }
                else
                {
                    logger.LogWarning($"Missing TrackerOAuth and/or X-Org-ID configuration properties. Tracker support will be turned off");
                }
            }
            else
            {
                logger.LogWarning($"Missing MlApiKey configuration property. Sentiment analyzis and Tracker support will be turned off.");
            }
                
        }



        public SpeechKitSttStreamClient Init(HttpContext context, WebSocket webSocket)
        {
            try
            {
                this.webSocket = webSocket;

                this.dbConn = new ApplicationDbContext(this.configuration);

                this.asrSession = new AsrSession();
                this.asrSession.TraceIdentifier = context.TraceIdentifier;
                this.asrSession.UserAgent = context.Request.Headers["User-Agent"];
                this.asrSession.RemoteIpAddress = context.Connection.RemoteIpAddress.ToString();
                this.dbConn.AsrSessions.Add(this.asrSession);
                
                if (substDictionary == null)
                {
                    this.dbConn.Substitutions.Load();
                    substDictionary = this.dbConn.Substitutions.ToDictionary(t => t.patternMatch, t => t.replacement);
                }

                speechKitClient = new SpeechKitSttStreamClient(new Uri("https://stt.api.cloud.yandex.net:443"),
                                                    this.args, this._loggerFactory);//
                                                                                    // Subscribe for speech to text events comming from SpeechKit
                SpeechToTextResponseReader.ChunkRecived += this.SpeechToTextResponseReader_AsrRecived;

                logger.LogInformation($"session {asrSession.AsrSessionId} started.");

                return speechKitClient;
            }catch(Exception ex)
            {
                Log.Fatal($"Error instantiating AsrProcessor {ex.Message} {ex.StackTrace}");
                return null;
            }
        }

        private  async void SpeechToTextResponseReader_AsrRecived(object sender, ChunkRecievedEventArgs e)
        {
            try
            {
                if (this.dbConn == null)
                    return;


                if (e.EventCase != StreamingResponse.EventOneofCase.Final
                            && e.EventCase != StreamingResponse.EventOneofCase.Partial
                                && e.EventCase != StreamingResponse.EventOneofCase.FinalRefinement)
                {
                    // unknown event - no text for processing                    
                    this.logger.LogWarning($"Skipping SpeechKit response event {e.EventCase}");
                    return;
                }
                
                request_in_progress = true;
               
                String jSonRes = e.AsJson(false);
                V3SpeechKitModels.SpeechKitResponseModel responseModel = mapResponseJson(e.EventCase, jSonRes);

                // Send response to WebSocket                    
                await Task.Run(() => this.ResponseToBrowser(responseModel));

                if (e.EventCase == StreamingResponse.EventOneofCase.FinalRefinement) {
                    
                    // Add final refinement to the list
                    this.finalRefinement = responseModel;
                    this.WholeRefinementText.Append(responseModel.GetWholeText());

                    // apply sentiment detection
                    Inference mlInference = await this.SentimentAnalysis(responseModel);
                    
                    this.lastPartialResponseId = Guid.Empty;
                    //this.AddResponse(responseModel);
                    lock (db_changes_locker)
                    {
                        this.dbConn.MlInferences.Add(mlInference);
                        int savedEntitiesCount = this.dbConn.SaveChanges();
                        logger.LogInformation($"db updated with {savedEntitiesCount} entities for {responseModel.RecognitionId} session {asrSession.AsrSessionId}");
                    }


                }
                else
                {                    

                    this.lastPartialResponseId = responseModel.RecognitionId;
                    logger.LogTrace($"Skip partial results {responseModel.RecognitionId}");
                }

                

            }
            catch(Exception ex)
            {
                logger.LogError($"Error {ex.Message} \n {ex.StackTrace} \n processing database updated from session {asrSession.AsrSessionId}");
            }
            finally
            {
                request_in_progress = false;
            }
        }

        private void AddResponse(SpeechKitResponseModel responseModel)
        {
            lock (db_changes_locker)
            {
                var previousResponse = this.dbConn.AsrResponses.Find(responseModel.RecognitionId);
                if (previousResponse != null)
                {
                    this.dbConn.Entry(previousResponse).CurrentValues.SetValues(responseModel);
                }
                else
                {
                    this.dbConn.AsrResponses.Add(responseModel);
                }
            }
        }

        private async Task<Inference> DoFinaleResponseTasks(SpeechKitResponseModel responseModel)
        {
            // apply sentiment detection
            Inference mlInference = await this.SentimentAnalysis(responseModel);
            // Attempt saving changes into to the database
            if (mlInference != null)
            {
                responseModel.TrackerKey = await this.CreateTrackerTask(responseModel, mlInference);
            }

            this.lastPartialResponseId = Guid.Empty;

            
            this.AddResponse(responseModel);

            lock (db_changes_locker) {
                
                this.dbConn.MlInferences.Add(mlInference);

                int savedEntitiesCount = this.dbConn.SaveChanges();
                logger.LogInformation($"db updated with {savedEntitiesCount} entities for {responseModel.RecognitionId} session {asrSession.AsrSessionId}");
            }

            return mlInference;
        }

        private V3SpeechKitModels.SpeechKitResponseModel mapResponseJson(StreamingResponse.EventOneofCase eventCase, String asrJson)
        {
            // Map response data 
            V3SpeechKitModels.SpeechKitResponseModel responseModel = JsonSerializer.Deserialize<V3SpeechKitModels.SpeechKitResponseModel>(asrJson);
               responseModel.SessionId = this.asrSession.AsrSessionId;
            //   responseModel.AudioLen = DateTime.Now.Subtract(this.audioStartMoment).TotalSeconds;
            /* Store response into database */           

            foreach (Alternative alt in responseModel.Alternatives)
            {
                alt.RecognitionId = responseModel.RecognitionId;
                alt.Text = SubstituteText(alt.Text);
                foreach (Word w in alt.Words)
                    w.AlternativeId = alt.AlternativeId;
            }

            return responseModel;
        }

        public static string SubstituteText(string inText)
        {
           return  substDictionary.Aggregate(inText, (current, value) =>
                    current.Replace(value.Key, value.Value, StringComparison.InvariantCultureIgnoreCase));
        }


        private async void ResponseToBrowser(SpeechKitResponseModel responseModel)
        {
            WssData data = new WssData()
            {
                asr_event_id = responseModel.RecognitionId,
                asr_event_type = responseModel.EventCase,
                text = responseModel.GetWholeText()

            };

            if (string.IsNullOrEmpty(data.text))
            {
                return;
            }

            WssPayload wpl = new WssPayload()
            {
                type = WssPayload.MSG_TYPE_DATA,
                data = JsonSerializer.Serialize(data)
            };
            await Task.Run(() => SendToWebsocket(wpl));

        }

        private async void SendToWebsocket(WssPayload wpl)
        {
            if (webSocket.State == WebSocketState.Open)
            {
                string jsonReplay = JsonSerializer.Serialize(wpl);
                byte[] bytePayload = Encoding.UTF8.GetBytes(jsonReplay);
                await webSocket.SendAsync(new ArraySegment<byte>(bytePayload, 0, bytePayload.Length),
                                WebSocketMessageType.Text, true, CancellationToken.None);
                logger.LogTrace($"session {asrSession.AsrSessionId} websocket: {wpl.type} successfullty sent.");
            }
            else
            {
                logger.LogWarning($"session {asrSession.AsrSessionId} websocket {webSocket.State}.");               
            }
        }

        private async Task<Inference> SentimentAnalysis(SpeechKitResponseModel responseModel)
        {            
            if (this.mlInference != null && responseModel.Alternatives != null && responseModel.Alternatives.Count > 0)
            {
                //  ml inference
                Inference emotions_list = await this.mlInference.SentimentAnalysis(responseModel);                
                emotions_list.text = responseModel.GetWholeText();

                if (emotions_list != null)
                {
                    //send to websocket
                    WssPayload wpl = new WssPayload()
                    {
                        type = WssPayload.MSG_TYPE_ML,
                        data = JsonSerializer.Serialize(emotions_list)
                    };
                    await Task.Run(() => SendToWebsocket(wpl));
                   

                    return emotions_list;
                }
            }
            return null;
        }



        private async Task<String> CreateTrackerTask(SpeechKitResponseModel responseModel, Inference mlResponse) {

            if (this.trackProcessor != null)
                return await this.trackProcessor.CreateTiket(responseModel, mlResponse);
            else
                return null;

        }

        /* Handle last partial results as final before close */
        internal async Task<Inference> SafeFinalResults()
        {

            if (this.finalRefinement == null)
            {
                if (final != null)
                {   // If we don't have final refinement - take final. 
                    this.finalRefinement = final;
                    this.finalRefinement.Final.Alternatives[0].Text = WholeFinalText.ToString();
                    this.finalRefinement.EventCase = StreamingResponse.EventOneofCase.FinalRefinement;
                }
                else
                {
                    return null;
                }
            }
            else
            {
                this.finalRefinement.FinalRefinement.NormalizedText.Alternatives[0].Text = this.WholeRefinementText.ToString();
            }                            

            return await DoFinaleResponseTasks(finalRefinement);            
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

                    this.mlInference = null;
                    this.trackProcessor = null;

                    logger.LogInformation($"session {asrSession.AsrSessionId} closed.");
                }
            }catch(Exception ex)
            {
                logger.LogError($"Error {ex.Message} during shutting down session {asrSession.AsrSessionId} ");
            }
            
        }
    }
}
