using Grpc.Core;
using Serilog;
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Speechkit.Stt.V3;

namespace ai.adoptionpack.speechkit.hybrid.client
{
    public class SpeechToTextResponseReader     {

        static internal event EventHandler<ChunkRecievedEventArgs> ChunkRecived;

        internal static Task ReadResponseStream(AsyncDuplexStreamingCall<StreamingRequest, StreamingResponse> grpcCall, CancellationToken cancelToken)
        {
            return Task.Factory.StartNew(async () =>
            {
                ILogger log = Log.Logger;
                log.Information("Started new ResponseStream reading task");
                try
                {
                    grpcCall.ResponseStream.MoveNext().Wait();
                    await foreach (var response in grpcCall.ResponseStream.ReadAllAsync())
                    {

                        log.Information($"{response.EventCase} chunk of {response.CalculateSize()} bytes recieved in {response.ResponseWallTimeMs}");

                        AlternativeUpdate altUpdate = null;
                        if (response.EventCase == StreamingResponse.EventOneofCase.Partial) {
                            altUpdate = response.Partial;
                        } else if (response.EventCase == StreamingResponse.EventOneofCase.Final) { 
                            altUpdate = response.Final;
                        }else if (response.EventCase == StreamingResponse.EventOneofCase.StatusCode && response.StatusCode.CodeType == CodeType.Closed)
                        {                         
                            log.Information($"Call compleated");
                            return;
                        }
                        
                        if (altUpdate != null)
                        {
                            ChunkRecievedEventArgs evt = new ChunkRecievedEventArgs(altUpdate, response.EventCase);
                            ChunkRecived?.Invoke(null, evt);
                           
                        }
                    }
                    
                }
                catch (RpcException ex) when (ex.StatusCode == Grpc.Core.StatusCode.DeadlineExceeded)
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
