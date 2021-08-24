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
using Yandex.Cloud.Ai.Stt.V2;
using YC.SpeechKit.Streaming.Asr.SpeechKitClient;

namespace YC.SpeechKit.Streaming.Asr
{

    class Client
    {
        public static IServiceProvider serviceProvider = ConfigureServices(new ServiceCollection());
        private static FileStream outFile;

        private static string notFinalBuf; // Last not final results
        static void Main(string[] args)
        {

            CommandLine.Parser.Default.ParseArguments<Options>(args)
                .WithParsed(RunOptions)
                .WithNotParsed(HandleParseError);

        }

        static void RunOptions(Options args)
        {
            ILoggerFactory _loggerFactory = Client.serviceProvider.GetService<ILoggerFactory>();
            _loggerFactory.AddSerilog();
            var logger = Log.Logger;


           

            try
            {
                outFile = File.OpenWrite(args.inputFilePath + ".speechkit.out");

                switch (args.mode)
                {
                    case Mode.stt_streaming:
                        
                        DoSttStreaming(args, _loggerFactory);
                        break;
                    case Mode.tts:
                        
                        DoTts(args, _loggerFactory);
                        break;
                    default:
                        Log.Error($"Wrong operation mode {args.mode}.");
                        break;
                }

                Log.Information($"Execution compleated. See results {outFile}");

            }
            catch (RpcException ex) when (ex.StatusCode == StatusCode.DeadlineExceeded)
            {
                Log.Error($"DeadlineExceeded: {ex.Message}");
            }
            catch (Exception ex)
            {
                Log.Error(ex.ToString());
            }
            finally
            {
                outFile.Flush();
                outFile.Close();
            }

        }

        /**
         * Синтез текста
         */
        static void DoTts(Options args, ILoggerFactory _loggerFactory)
        {
            SpeechKitTtsClient ttsClient = new SpeechKitTtsClient(new Uri("https://tts.api.cloud.yandex.net"),  //https://tts.api.cloud.yandex.net:443
                args.folderId, args.iamToken, _loggerFactory);


            ttsClient.TextToSpeachResultsRecieved += TtsClient_TextToSpeachResultsRecieved;

            ttsClient.SynthesizeTxtFile(args.inputFilePath, args.model);
        }

        //static int i = 0;
        private static async void TtsClient_TextToSpeachResultsRecieved(object sender, AudioDataEventArgs e)
        {
            try
            {

               /* await File.WriteAllBytesAsync($"C:\\tmp\\{i}.wav", e.AudioData);
                await File.AppendAllTextAsync("C:\\tmp\\concat_files.txt", $"file '{i}.wav'\n" );
                i++;*/
                outFile.Write(e.AudioData, 0, e.AudioData.Length);
                await outFile.FlushAsync();


            }
            catch (Exception ex)
            {
                Log.Error(ex.ToString());
            }
        }

        /**
         * Режим потокового распозанвания текста
         */
        static void DoSttStreaming(Options args, ILoggerFactory _loggerFactory)
        {
           

                RecognitionSpec rSpec = new RecognitionSpec()
                {
                    LanguageCode = args.lang,
                    ProfanityFilter = false,
                    Model = args.model,
                    PartialResults = false, //возвращать только финальные результаты false
                    AudioEncoding = args.audioEncoding,
                    SampleRateHertz = args.sampleRate
                };

            
            SpeechKitSttStreamClient speechKitClient =
                    new SpeechKitSttStreamClient(new Uri("https://stt.api.cloud.yandex.net:443"), args.folderId, args.iamToken, rSpec, _loggerFactory);
                // Subscribe for speech to text events comming from SpeechKit
                SpeechKitClient.SpeechToTextResponseReader.ChunkRecived += SpeechToTextResponseReader_ChunksRecived;


                FileStreamReader filereader = new FileStreamReader(args.inputFilePath);
                // Subscribe SpeechKitClient for next portion of audio data
                filereader.AudioBinaryRecived += speechKitClient.Listener_SpeechKitSend;
                filereader.ReadAudioFile().Wait();

                Log.Information("Shutting down SpeechKitStreamClient gRPC connections.");
                speechKitClient.Dispose();

                if (!string.IsNullOrEmpty(notFinalBuf))
                {
                    outFile.Write(Encoding.UTF8.GetBytes(notFinalBuf)); //Write final results into file                                     
                }           
           
        }

        static void HandleParseError(IEnumerable<Error> errs)
        {
            Log.Error($"Command line arguments parsing error.");
        }

        private static void SpeechToTextResponseReader_ChunksRecived(object sender, ChunkRecievedEventArgs e)
        {
            notFinalBuf = e.AsJson();
            Log.Information(notFinalBuf); // Log partial results

            if (e.SpeechToTextChunk.Final)
            {
                outFile.Write(Encoding.UTF8.GetBytes(notFinalBuf)); //Write final results into file                
                notFinalBuf = null; 
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

        [Option("mode", Required = false, Default = Mode.stt_streaming, HelpText = "Operation mode: stt_streaming - streaming s2t,  tts - text to speech")]
        public Mode mode { get; set; }


        [Option("lang", Required = false, Default = "ru-RU", HelpText = "Language: ru-RU en-US - kk-KK")]
        public string lang { get; set; }

        [Option("iam-token", Required = true, HelpText = "Specify the received IAM token when accessing Yandex.Cloud SpeechKit via the API.")]
        public string iamToken { get; set; }

       [Option("folder-id", Required = true, HelpText = "ID of the folder that you have access to.")]
        public String folderId { get; set; }

        [Option("in-file", Required = true, HelpText = "Path of the audio file for recognition. Path to text file for tts synthezis")]
        public string inputFilePath { get; set; }

        [Option("model", Required = false, Default = "general", HelpText = "S2T model: deferred-general/ hqa/ general:rc/ general:deprecated")]
        public string model { get; set; }

        [Option("audio-encoding", Required = true, HelpText = "The format of the submitted audio. Acceptable values: Linear16Pcm, OggOpu.")]
        public RecognitionSpec.Types.AudioEncoding audioEncoding { get; set; }

        [Option("sample-rate", Required = false, Default = 48000, HelpText = "The sampling frequency of the submitted audio (48000, 16000, 8000). Required if format is set to Linear16Pcm")]
        public int sampleRate { get; set; }

    }


    public enum Mode
    {
        stt_streaming,        
        tts
    }
}
