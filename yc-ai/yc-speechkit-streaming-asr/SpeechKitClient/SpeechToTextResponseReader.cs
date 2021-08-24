using Grpc.Core;
using Serilog;
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Yandex.Cloud.Ai.Stt.V2;

namespace YC.SpeechKit.Streaming.Asr.SpeechKitClient
{
    public class SpeechToTextResponseReader     {

        static internal event EventHandler<ChunkRecievedEventArgs> ChunkRecived;

        internal static Task ReadResponseStream(AsyncDuplexStreamingCall<StreamingRecognitionRequest, StreamingRecognitionResponse> grpcCall)
        {
            return Task.Factory.StartNew(async () =>
            {
                ILogger log = Log.Logger;
                log.Information("Started new ResponseStream reading task");
                try
                {                  
                    await foreach (var response in grpcCall.ResponseStream.ReadAllAsync())
                     {
                        log.Information($"s2t chunk of {response.CalculateSize()} bytes recieved ");
                        foreach (SpeechRecognitionChunk chunk in response.Chunks)
                        {
                            ChunkRecievedEventArgs evt = new ChunkRecievedEventArgs(chunk);
                            ChunkRecived?.Invoke(null, evt);
                        }   
                     }
                }
                catch (RpcException ex) when (ex.StatusCode == StatusCode.DeadlineExceeded)
                {
                    // Check for details https://cloud.yandex.com/docs/speechkit/stt/streaming#session-restrictions
                    log.Information($"Session limit riched {ex.Message}  with status {ex.Status} code {ex.StatusCode}"); 
                }
                catch (RpcException ex) 
                {
                    log.Error($"ResponseStream err {ex.Message}  with status {ex.Status} code {ex.StatusCode}");
                }
                catch(Exception ex){
                    log.Error($"Error during read {ex.Message}");
                }
            });
        }
    }
}
