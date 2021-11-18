using Grpc.Core;
using System;
using System.Text;
using System.Threading.Tasks;

using Speechkit.Stt.V3;
using Serilog;
using System.Threading;
using Grpc.Net.Client;
using Microsoft.Extensions.Logging;


namespace ai.adoptionpack.speechkit.hybrid.client
{
    class SpeechKitSttStreamClient : SpeechKitAbstractClient, IDisposable
    {

        public event EventHandler<ChunkRecievedEventArgs> SpeechToTextResultsRecived;

        private StreamingOptions sessionConf;
        
        
        private Recognizer.RecognizerClient speechKitRpcClient;

        private const int MAX_BYTES_SENT = 32 * 1024; // check https://cloud.yandex.com/docs/speechkit/stt/streaming#session-restrictions for limitation details


        private void _readTask_SpeechToTextResultsRecived(object sender, ChunkRecievedEventArgs e)
        {
            SpeechToTextResultsRecived?.Invoke(sender,e);
        }

        public SpeechKitSttStreamClient(Uri address, Options rSpec, ILoggerFactory loggerFactory) : base(address) {
            this.sessionConf = new StreamingOptions()
            {
                  RecognitionModel = new RecognitionModelOptions() { 
                      Model = "general",
                      /*AudioFormat = new AudioFormatOptions()
                      {
                          RawAudio = new RawAudio()
                          {
                               AudioEncoding = RawAudio.Types.AudioEncoding.Linear16Pcm,
                                SampleRateHertz = 48000,
                                 AudioChannelCount = 1
                          }
                          }*/
                           AudioFormat = new AudioFormatOptions() { 
                               ContainerAudio = new ContainerAudio() { 
                                   ContainerAudioType =  rSpec.audioEncoding                                   
                               }
                           }
                      }
            };
            speechKitRpcClient = new Recognizer.RecognizerClient(MakeChannel(loggerFactory));


        }

        

       internal Task SendAsrData(byte[] audio, CancellationToken cancelToken)
        {
            try
            {

                AsyncDuplexStreamingCall<StreamingRequest, StreamingResponse> call = speechKitRpcClient.RecognizeStreaming();
                //  headers: this.MakeMetadata(), 
                //   deadline: DateTime.UtcNow.AddMinutes(5));  // check https://cloud.yandex.com/docs/speechkit/stt/streaming#session-restrictions for limitation details
                StreamingRequest rR = new StreamingRequest();
                rR.SessionOptions = this.sessionConf;

                call.RequestStream.WriteAsync(rR).Wait();

                
                Task responseReader = SpeechToTextResponseReader.ReadResponseStream(call, cancelToken);

                Task.Factory.StartNew(() =>
                {
                    for (int offset = 0; offset < audio.Length; offset += MAX_BYTES_SENT) {
                        rR = new StreamingRequest();

                        rR.Chunk = new AudioChunk()
                        {
                            Data = Google.Protobuf.ByteString.CopyFrom(audio, offset, offset + MAX_BYTES_SENT > audio.Length ? audio.Length - offset : MAX_BYTES_SENT)
                        };

                        call.RequestStream.WriteAsync(rR).Wait();
                    }

                    call.RequestStream.CompleteAsync().Wait(); // Почему-то данные возвращаются после закрытия потока
                    Log.Information($"{audio.Length} bytes sent to service");
                });

                return responseReader;



            }
            catch (RpcException ex) //when (ex.StatusCode == StatusCode.DeadlineExceeded)
            {
                Log.Error($"during data sent error: {ex.Message}  with status {ex.Status} code {ex.StatusCode}");
                throw ex;
            }
            }




        public void Dispose()
        {
           /* bool locked = callMutex.WaitOne(5 * 1000); // Всеравно тайм аут наступет через 5 сек. после прекращения записи на сервисе
            while (locked)
            {
                try
                {
                    if (this._call != null)
                    {
                        Status status = this._call.GetStatus(); // throw exception if not done
                        log.Information("Shutting down SpeechKit grpc connection.");
                        this._call.Dispose();
                        this._call = null;
                    }
                    
                    callMutex.ReleaseMutex();
                    locked = false;
                }
                catch (Exception ex)
                {
                    log.Information($"Waiting call for compleation. ${ex.Message}");
                    Thread.Sleep(1000);            
                }
            }*/
 
        }
    }
}
