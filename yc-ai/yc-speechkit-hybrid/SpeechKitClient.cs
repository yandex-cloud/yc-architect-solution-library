using CommandLine;
using Grpc.Core;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Serilog;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading;
using ai.adoptionpack.speechkit.hybrid.client;
using Speechkit.Stt.V3;

namespace ai.adoptionpack.speechkit.hybrid
{

    public class SpeechKitClient
    {
        public static IServiceProvider serviceProvider = ConfigureServices(new ServiceCollection());

        private static String PartialTextResultsOutFile{
            get { return args.inputFilePath + ".partial.txt"; }
        }

        private static String FinalTextResultsOutFile
        {
            get { return args.inputFilePath + ".Final.txt"; }
        }

       private static String TraceResultsOutFile
        {
            get { return args.inputFilePath + ".trace.json"; }
        }

        public static CancellationTokenSource cancelSource = new CancellationTokenSource();
        static Options args;
        static void Main(string[] args)
        {

            CommandLine.Parser.Default.ParseArguments<Options>(args)
                .WithParsed(RunOptions)
                .WithNotParsed(HandleParseError);

        }

        static void RunOptions(Options args)
        {
            ILoggerFactory _loggerFactory = SpeechKitClient.serviceProvider.GetService<ILoggerFactory>();
            _loggerFactory.AddSerilog();
            var logger = Log.Logger;
            SpeechKitClient.args = args;


            try
            {
                

                switch (args.mode)
                {
                    case Mode.stt:
                        
                        DoSttStreaming( _loggerFactory);
                        break;
                    case Mode.tts:
                        
                        DoTts( _loggerFactory);
                        break;
                    default:
                        Log.Error($"Wrong operation mode {args.mode}.");
                        break;
                }

                Log.Information($"Execution compleated.");

            }
            catch (RpcException ex) when (ex.StatusCode == Grpc.Core.StatusCode.DeadlineExceeded)
            {
                Log.Error($"DeadlineExceeded: {ex.Message}");
            }
            catch (Exception ex)
            {
                Log.Error(ex.ToString());
            }
            

        }

        /**
         * Режим потокового синтез аудио
         */
        static void DoTts(ILoggerFactory _loggerFactory)
        {
           /* TODO */
        }



        /**
         * Режим потокового распозанвания текста
         */
        static void DoSttStreaming( ILoggerFactory _loggerFactory)
        {
                       
            SpeechKitSttStreamClient speechKitClient =
                    new SpeechKitSttStreamClient(new Uri(args.serviceUri), args, _loggerFactory);

            SpeechToTextResponseReader.ChunkRecived += SpeechToTextResponseReader_ChunksRecived;


            FileStreamReader filereader = new FileStreamReader(args.inputFilePath);
            // Subscribe SpeechKitClient for next portion of audio data
            filereader.AudioBinaryRecived += speechKitClient.Listener_SpeechKitSend;
            filereader.ReadAudioFile().Wait();

            Log.Information("Shutting down SpeechKitStreamClient gRPC connections.");
            Thread.Sleep(15000);
            speechKitClient.Dispose();

            Log.Information($"Final results output file: {FinalTextResultsOutFile}");
            Log.Information($"Partial results output file: {PartialTextResultsOutFile}");
            Log.Information($"Trace service output file: {TraceResultsOutFile}");
        }



        static void HandleParseError(IEnumerable<Error> errs)
        {
            Log.Error($"Command line arguments parsing error.");
        }

        private static void SpeechToTextResponseReader_ChunksRecived(object sender, ChunkRecievedEventArgs e)
        {
            String eventPayload = e.AsJson(true);
            Log.Information(eventPayload); // Log partial results
           
           File.AppendAllText(TraceResultsOutFile, eventPayload);//Write final results into file     

           if (e.EventCase == StreamingResponse.EventOneofCase.Final)
           {

                File.AppendAllText(FinalTextResultsOutFile, eventPayload);
                // File.AppendAllText(FinalTextResultsOutFile, Helpers.extractText(eventPayload, "Final.Alternatives[*].Text"));//Write final results into file    


            }
            else if (e.EventCase == StreamingResponse.EventOneofCase.Partial)
            {
                string PartialTextResultsTxtFile = args.inputFilePath + ".partial.txt";
                // File.AppendAllText(PartialTextResultsTxtFile, Helpers.extractText(eventPayload, "Partial.Alternatives[*].Text"));//Write partial results into file
                File.AppendAllText(PartialTextResultsTxtFile, eventPayload);

                Log.Information($"Results output file: {PartialTextResultsTxtFile}");
            }else if (e.EventCase == StreamingResponse.EventOneofCase.FinalRefinement)
            {
                string FinalRefinementTextResultsFile = args.inputFilePath + ".FinalRefinement.txt";
                File.AppendAllText(FinalRefinementTextResultsFile, eventPayload);
                //File.AppendAllText(FinalRefinementTextResultsFile, Helpers.extractText(eventPayload, "FinalRefinement.Alternatives[*].Text"));//Write partial results into file    
            }

        }



        private static IServiceProvider ConfigureServices(IServiceCollection services)
        {
            var builder = new ConfigurationBuilder()
                    .SetBasePath(Directory.GetCurrentDirectory())
                    .AddJsonFile("appsettings.json");

            var config = builder.Build();

            Log.Logger = new LoggerConfiguration()
                           .ReadFrom.Configuration(config)
                           .Enrich.FromLogContext()
                        .MinimumLevel.Debug()
                           .CreateLogger();

            services.AddSingleton<ILoggerFactory, LoggerFactory>();

            services.AddLogging();

            var serviceProvider = services.BuildServiceProvider();
            return serviceProvider;

        }
    }

    public class Options 
    {


        [Option("mode", Required = false, Default = Mode.stt, HelpText = "Operation mode: stt_streaming - streaming s2t,  tts - text to speech")]
        public Mode mode { get; set; }

        [Option("lang", Required = false, Default = "ru-RU", HelpText = "Language: ru-RU en-US - kk-KK")]
        public string lang { get; set; }

        [Option("service-uri", Required = true, HelpText = "uri of the service: http:////ip-or_host:port_")]
        public string serviceUri { get; set; }

        [Option("token-type", Required = true, HelpText = "Specify token type. Can be  APIKey or IAM.")]
        public AuthTokenType TokenType { get; set; }

        [Option("token", Required = true, HelpText = "Specify the received IAM or ApiKey token when accessing Yandex.Cloud SpeechKit via the API.")]
        public string Token { get; set; }

        [Option("in-file", Required = true, HelpText = "Path of the audio file for recognition. Path to text file for tts synthezis")]
        public string inputFilePath { get; set; }

        [Option("model", Required = false, Default = "general", HelpText = "S2T model: deferred-general/ hqa/ general:rc/ general:deprecated")]
        public string model { get; set; }

        [Option("audio-format", Required = true, HelpText = "The format of the submitted audio. Acceptable values (case sensitive): Wav, OggOpus.")]
        public ContainerAudio.Types.ContainerAudioType audioEncoding { get; set; }

        [Option("sample-rate", Required = false, Default = 48000, HelpText = "The sampling frequency of the submitted audio (48000, 16000, 8000). Required if format is set to Linear16Pcm")]
        public int sampleRate { get; set; }

    }


    public enum Mode
    {
        stt,        
        tts
    }
}
