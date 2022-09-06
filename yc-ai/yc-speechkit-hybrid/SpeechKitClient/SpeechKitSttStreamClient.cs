﻿using Grpc.Core;
using System;
using System.Text;
using System.Threading.Tasks;

using Speechkit.Stt.V3;
using Serilog;
using System.Threading;
using Grpc.Net.Client;
using Microsoft.Extensions.Logging;
using System.Reflection.PortableExecutable;
using System.IO;

namespace ai.adoptionpack.speechkit.hybrid.client
{
    public class SpeechKitSttStreamClient : SpeechKitAbstractClient
    {

        public event EventHandler<ChunkRecievedEventArgs> SpeechToTextResultsRecived;

        private StreamingOptions sessionConf;

        private Task _readTask;
        private Recognizer.RecognizerClient speechKitRpcClient;
        private int bytesSent = 0;
        private const int MAX_BYTES_SENT = 10 * 1024 * 1024; // check https://cloud.yandex.com/docs/speechkit/stt/streaming#session-restrictions for limitation details


        private void _readTask_SpeechToTextResultsRecived(object sender, ChunkRecievedEventArgs e)
        {
            SpeechToTextResultsRecived?.Invoke(sender,e);
        }

        private AsyncDuplexStreamingCall<StreamingRequest, StreamingResponse> _call;

        private async Task<AsyncDuplexStreamingCall<StreamingRequest, StreamingResponse>> ActiveCall()
        {

                if (this._call != null)
                {
                    log.Verbose($"Reuse exisiting grpc session for call.");
                    return this._call;
                }

                try
                {
                    Log.Information($"Initialize gRPC call");
                    this._call = speechKitRpcClient.RecognizeStreaming(
                            headers: this.MakeMetadata(),
                            deadline: DateTime.UtcNow.AddMinutes(5));
                    this.bytesSent = 0; // reset bytes counter


                    StreamingRequest rR = new StreamingRequest()
                    {
                        SessionOptions = this.sessionConf
                    };

                    await this._call.RequestStream.WriteAsync(rR);

                    // Start reading task for call                    
                    this._readTask = SpeechToTextResponseReader.ReadResponseStream(this._call);

                    return this._call;

                }
                catch (Exception ex) //when (ex.StatusCode == StatusCode.DeadlineExceeded)
                {
                    Log.Error($"during data sent exception {ex.Message} ");
                    throw ex;
                }

        }

        private FileStream debugStream = File.OpenWrite(@"c:\\tmp\debug_audio.wav");

        public SpeechKitSttStreamClient(Uri address, Options rSpec, ILoggerFactory loggerFactory) : base(address, rSpec.TokenType, rSpec.Token) {
            this.sessionConf = new StreamingOptions()
            {
                RecognitionModel = new RecognitionModelOptions() {
                     AudioFormat = new AudioFormatOptions() {
                         RawAudio = new RawAudio() {
                             AudioEncoding = RawAudio.Types.AudioEncoding.Linear16Pcm,
                             SampleRateHertz = rSpec.sampleRate,
                             AudioChannelCount = 1
                         }
                        /* ContainerAudio = new ContainerAudio()
                         {
                              ContainerAudioType = ContainerAudio.Types.ContainerAudioType.Wav
                         }*/
                    },
                    TextNormalization = new TextNormalizationOptions()
                    {
                        TextNormalization = TextNormalizationOptions.Types.TextNormalization.Enabled,
                        ProfanityFilter = false,
                        LiteratureText = true
                    },
                    AudioProcessingType =  RecognitionModelOptions.Types.AudioProcessingType.RealTime
                }
            };
            speechKitRpcClient = new Recognizer.RecognizerClient(MakeChannel(loggerFactory));


          

        }


        public async void Listener_SpeechKitSend(object sender, AudioDataEventArgs e)
        {


                // recreate connection if we send more them 10 Mb                    
                this.bytesSent += e.AudioData.Length;
                if (this.bytesSent >= MAX_BYTES_SENT)
                    this._call = null;
                try
                {
                    await Task.Run(() => WriteAudio(e.AudioData));
                }
                catch (Exception ex) //when (ex.StatusCode == StatusCode.DeadlineExceeded)
                {
                    Log.Error($"Error writing data: {ex.Message}\n Retrying... ");
                    this._call = null;
                    WriteAudio(e.AudioData);

                }            
            
        }


        private async void WriteAudio(byte[] audioData)
        {
            try
            {
                //DEBUG
                //debugStream.Write(audioData, 0, audioData.Length);

                AsyncDuplexStreamingCall<StreamingRequest, StreamingResponse> call =  await this.ActiveCall();
                StreamingRequest rR = new StreamingRequest();
                rR.Chunk = new AudioChunk(){Data = Google.Protobuf.ByteString.CopyFrom(audioData)};
                    
                 await call.RequestStream.WriteAsync(rR);
            }
            catch (RpcException ex) //when (ex.StatusCode == StatusCode.DeadlineExceeded)
            {
                Log.Error($"during data sent error: {ex.Message}  with status {ex.Status} code {ex.StatusCode}");
                throw ex;
            }
        }


        public void Dispose()
        {
           
                try
                {
                    if (this._readTask != null)
                    {
                        log.Information($"Disposing reading tasks");
                        this._readTask.Dispose(); // Close read task
                    }
                    this._readTask = null;

                    if (this._call != null)
                    {
                        //Status status = this._call.GetStatus();  throw exception if not done
                        log.Information("Shutting down SpeechKit grpc connection.");
                        this._call.RequestStream.CompleteAsync();
                        
                        this._call.Dispose();
                        this._call = null;
                    }
                    
                }
                catch (Exception ex)
                {
                    log.Information($"Waiting call for compleation. ${ex.Message}");
                    Thread.Sleep(1000);
                }
        }

    }
}