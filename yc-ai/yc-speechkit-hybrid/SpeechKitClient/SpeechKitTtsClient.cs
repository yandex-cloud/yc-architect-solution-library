using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading;
using System.Text.RegularExpressions;
using Grpc.Core;
using Grpc.Net.Client;
using Microsoft.Extensions.Logging;
using Speechkit.Tts.V3;
using System.Threading.Tasks;
using System.Runtime.CompilerServices;
using Newtonsoft.Json.Linq;

namespace ai.adoptionpack.speechkit.hybrid.client
{
    public class SpeechKitTtsClient : SpeechKitAbstractClient, IDisposable
    {

        private const int MAX_LINE_LENGTH = 160;  //Ограничение на длину строки: 160 символов. https://cloud.yandex.ru/docs/speechkit/tts/request

        private Synthesizer.SynthesizerClient synthesizerClient;

        public event EventHandler<AudioDataEventArgs> TextToSpeachResultsRecieved;

        private UtteranceSynthesisRequest ActiveRequest { get; set; }
        private String FolderId;

        public SpeechKitTtsClient(Uri address, AuthTokenType tokenType, string Token, string folderId, ILoggerFactory loggerFactory) : base(address, tokenType, Token)
        {
            this.endpointAddress = address;
            this.FolderId = folderId;
                     
            synthesizerClient = new Synthesizer.SynthesizerClient(MakeChannel(loggerFactory));
        }


        public void SynthesizeTxtFile(string inputFilePath, string model)
        {          
            SynthesizeTxtLine(File.ReadAllText(inputFilePath), model);
        }

        private void SynthesizeTxtLine(string text, string model)
        {
            StringBuilder ttsBuffer = new StringBuilder(MAX_LINE_LENGTH);

            string[] parts = Regex.Split(text, @"(?<=[.,;])");

            foreach (String line in parts)
            {
                if (!string.IsNullOrWhiteSpace(line))
                {
                    if (ttsBuffer.Length + line.Length >= MAX_LINE_LENGTH)
                    {
                        SynthesizeTxtBuffer(ttsBuffer.ToString(), model);
                        ttsBuffer = new StringBuilder(MAX_LINE_LENGTH);
                    }

                    ttsBuffer.AppendLine(line);
                }
            }

            if (ttsBuffer.Length > 0)
            {
                SynthesizeTxtBuffer(ttsBuffer.ToString(), model);
            }
        }


        private async void SynthesizeTxtBuffer(string text, string model)
        {

                UtteranceSynthesisRequest request = MakeRequest(text, model);
              //   request.Hints.Add(new Hints() { Voice = "kuznetsov_male" });

                Metadata callHeaders = this.MakeMetadata();
                callHeaders.Add("x-folder-id", this.FolderId);


                CancellationTokenSource cancellationSource = new CancellationTokenSource();

                    var call = synthesizerClient.UtteranceSynthesis(request, headers: callHeaders,
                            deadline: DateTime.UtcNow.AddMinutes(5));

                    log.Information($"synthizing: {text}");
                    var respEnum = call.ResponseStream.ReadAllAsync(cancellationSource.Token).GetAsyncEnumerator();
                    try
                    {

                        ValueTaskAwaiter<bool> tsk = respEnum.MoveNextAsync().GetAwaiter();

                        tsk.OnCompleted(() =>
                        {
                            if (respEnum.Current != null)
                            {
                                byte[] data = respEnum.Current.AudioChunk.Data.ToByteArray();
                                TextToSpeachResultsRecieved?.Invoke(this, AudioDataEventArgs.FromByateArray(data, data.Length));
                                log.Information($"Audio chunk {data.Length} bytes recieved.");
                            }
                            else
                            {
                                log.Warning("No data in response");
                            }
                        });
                          

                        while (!tsk.IsCompleted)
                        {
                            Thread.Sleep(200);
                        }

                        return;

                     }
                    catch (Exception ex)
                    {
                        log.Error(ex.Message);
                    }
                    finally
                    {
                        if (respEnum != null)
                            await respEnum.DisposeAsync();                
                }
                
            
        }

        private static UtteranceSynthesisRequest MakeRequest(string text, string model)
        {
            UtteranceSynthesisRequest utteranceRequest = new UtteranceSynthesisRequest
            {
                Model = model,
                Text = text,
                OutputAudioSpec = new AudioFormatOptions
                {
                   /* RawAudio = new RawAudio
                    {                        
                         AudioEncoding = RawAudio.Types.AudioEncoding.Linear16Pcm,
                          SampleRateHertz = 22050
                    }*/
                    ContainerAudio = new ContainerAudio
                    {
                        ContainerAudioType = ContainerAudio.Types.ContainerAudioType.Wav
                    }
               }
            };

            return utteranceRequest;
        }

        public void Dispose()
        {
            
        }
    }
}
