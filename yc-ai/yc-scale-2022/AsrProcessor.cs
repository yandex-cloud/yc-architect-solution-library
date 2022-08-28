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

            speechKitClient =  new SpeechKitSttStreamClient(new Uri("https://stt.api.cloud.yandex.net:443"), 
                                                    "b1gvp43cei68d5sfhsu7", 
                                                    "t1.9euelZrGjJDGnsqRmpSYlpDMmpiOx-3rnpWaksyWzMmRlpTPmcaPncvKzJDl8_ddeFJn-e9OLWgo_t3z9x0nUGf5704taCj-.KJuFgk_lwX4tiJ3is6P7BBelMKru6dyCoYRRuAhyoReblK5p512VNYeE8zWlxT_oLR7qTz1nIv_Ki1vMgc0aBg",
                                                this.rSpeс, this._loggerFactory);//
                                                                       // Subscribe for speech to text events comming from SpeechKit
            SpeechToTextResponseReader.ChunkRecived += this.SpeechToTextResponseReader_ChunksRecived;

            controller.AudioBinaryRecived += speechKitClient.Listener_SpeechKitSend;
        }

        private void SpeechToTextResponseReader_ChunksRecived(object sender, ChunkRecievedEventArgs e)
        {
           
            

            var wssResponseTask = new Task(() =>
            {
                this.ResponseToBrowser(e.AsJson(false));
            });

            wssResponseTask.Start();

        }

        private async void ResponseToBrowser(String asrJson)
        {
            if (webSocket.State == WebSocketState.Open)
            {

                asrJson = "{ \"Chunks\": [" + asrJson + "]}";
                
                WssPayload wpl = new WssPayload() { type = WssPayload.MSG_TYPE_DATA, data = asrJson };
                string jsonReplay = JsonSerializer.Serialize(wpl);
                byte[] bytePayload = Encoding.UTF8.GetBytes(jsonReplay);
                    await webSocket.SendAsync(new ArraySegment<byte>(bytePayload, 0, bytePayload.Length),
                                WebSocketMessageType.Text, true, CancellationToken.None); 
            }
            else
            {
                logger.LogWarning($"session {AsrSessionId} websocket closed. Error sending {asrJson}");
            }
        }


        public void Dispose()
        {

            // TODO: Wait tasks to compleate
           if (this.speechKitClient != null)
            {
                this.speechKitClient.Dispose();
                this.speechKitClient = null;

            }
        }
    }
}
