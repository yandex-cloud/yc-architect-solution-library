using Amazon.S3;
using CommandLine;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;
using Serilog;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using Yandex.Cloud.Ai.Stt.V2;

namespace SkBatchAsrClient
{


    class SkBatchAsrClient
    {
        public static IServiceProvider serviceProvider { get; private set; }

        
      //  public static Configuration Config { get; private set; }

        static void Main(string[] args)
        {
            CommandLine.Parser.Default.ParseArguments<Configuration>(args)
               .WithParsed(RunOptions)
               .WithNotParsed(HandleParseError);
        }

        static void RunOptions(Configuration cfg)
        {
            serviceProvider = ConfigureServices(new ServiceCollection(), cfg);
            ILoggerFactory _loggerFactory = SkBatchAsrClient.serviceProvider.GetService<ILoggerFactory>();
            _loggerFactory.AddSerilog();

            var logger = Log.Logger;
            try
            {
               if (cfg.mode.Equals(Mode.stt_create_tasks))
                {
                    Log.Information($"Create recognition task for .wav files in s3 bucket {cfg.bucket}");
                    DoCreateTasks(cfg, _loggerFactory);
                }else if (cfg.mode.Equals(Mode.stt_task_results))
                {
                    Log.Information($"Read tasks results from {cfg.tasksFile}");
                    DoTaskResults(cfg, _loggerFactory);
                }
                else
                {
                    throw new ArgumentException();
                }
            }
            catch (Exception ex)
            {
                Log.Error(ex.ToString());
            }

            Log.Information("Execution compleated.");
        }

        static void HandleParseError(IEnumerable<Error> errs)
        {
            Log.Error($"Command line arguments parsing error.");
        }


        private static void DoTaskResults(Configuration cfg, ILoggerFactory _loggerFactory)
        {
            SkTaskDb taskDb = new SkTaskDb(cfg.tasksFile, Log.Logger);

            HttpClient httpClient = new HttpClient();
            httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", cfg.iamToken);

            foreach (SkTaskModel task in taskDb.Tasks)
            {
                if (!taskDb.CheckCompleated(cfg.bucket, task))
                {
                    string taskResults = @"https://operation.api.cloud.yandex.net/operations/" + task.TaskId;
                    var response = httpClient.GetStringAsync(taskResults).GetAwaiter().GetResult();

                    dynamic jsonResponse = JObject.Parse(response);

                    if ((bool)jsonResponse.done)
                    {
                        string txtFile = taskDb.StoreResults(jsonResponse, cfg.bucket, task);

                        Log.Information($"Task {task.TaskId} text sucessfully stored to {txtFile}");
                    }
                    else
                    {
                        Log.Logger.Warning($"Task {task.TaskId} is not compleated");
                    }
                }
                else
                {
                    Log.Logger.Warning($"Task {task.TaskId} already compleated");
                }
                
            }
        }

       private static void DoCreateTasks(Configuration cfg, ILoggerFactory _loggerFactory)
        {
            IS3Client s3Client = serviceProvider.GetService<IS3Client>();

            SkTaskDb taskDb = new SkTaskDb(cfg.tasksFile, Log.Logger);


            RecognitionSpec rSpec = new RecognitionSpec()
            {
                LanguageCode = cfg.lang,
                ProfanityFilter = true,
                Model = cfg.model,
                PartialResults = false, //возвращать только финальные результаты false
                AudioEncoding = cfg.audioEncoding,
                SampleRateHertz = cfg.sampleRate
            };

            SkRecognitionClient recognitionClient = new SkRecognitionClient(new Uri("https://stt.api.cloud.yandex.net:443"),
                cfg.folderId, cfg.iamToken, rSpec, _loggerFactory, taskDb);

            s3Client.ProcessBucket(cfg.bucket, recognitionClient);

            Log.Information($"Found {taskDb.Count} objects");
        }

        private static IServiceProvider ConfigureServices(IServiceCollection services, Configuration Config)
        {
            var builder = new ConfigurationBuilder()
                    .SetBasePath(Directory.GetCurrentDirectory())
                    .AddJsonFile("appsettings.json");

            var config = builder.Build();


            #region AmazonS3Client

            AmazonS3Config ycConfig = new AmazonS3Config();
            ycConfig.ServiceURL = Config.serviceURL;
            Amazon.Runtime.AWSCredentials credentials = new Amazon.Runtime.BasicAWSCredentials(
                        Config.accessKey,
                       Config.secretKey);
            services.AddTransient<IAmazonS3>(_ =>
                      new AmazonS3Client(credentials, ycConfig));

            services.AddSingleton<IS3Client, S3Client>();

            #endregion


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

    public enum Mode
    {
        stt_create_tasks,
        stt_task_results,
        tts
    }



    public class Configuration
    {
            [Option("mode", Required = false, Default = Mode.stt_create_tasks, HelpText = "Operation mode: stt_create_tasks, stt_task_results, tts")]
            public Mode mode { get; set; }

            [Option("s3-accessKey", Required = true, HelpText = "Yandex Object Storage access key.")]
            public string accessKey { get; set; }

            [Option("s3-secretKey", Required = true, HelpText = "Yandex Object Storage secret key")]
            public String secretKey { get; set; }


            [Option("bucket", Required = true, HelpText = "Yandex Object Storage bucket.")]
            public string bucket { get; set; }

            [Option("tasksFile", Required = false, Default = "tasks.csv", HelpText = "file to store recognition tasks information")]
            public string tasksFile { get; set; }

            [Option("serviceURL", Required = false, Default = "https://storage.yandexcloud.net",  HelpText = "Yandex Object Storage serviceURL.")]
            public string serviceURL { get; set; }

            [Option("iam-token", Required = true, HelpText = "Specify the received IAM token when accessing Yandex.Cloud SpeechKit via the API.")]
            public string iamToken { get; set; }

            [Option("folder-id", Required = true, HelpText = "ID of the folder that you have access to.")]
            public String folderId { get; set; }

            [Option("audio-encoding", Required = true, HelpText = "The format of the submitted audio. Acceptable values: Linear16Pcm, OggOpu.")]
            public RecognitionSpec.Types.AudioEncoding audioEncoding { get; set; }

            [Option("model", Required = false, Default = "general", HelpText = "S2T model: deferred-general/ hqa/ general:rc/ general:deprecated")]
            public string model { get; set; }

            [Option("lang", Required = false, Default = "ru-RU", HelpText = "Language: ru-RU en-US - kk-KK")]
            public string lang { get; set; }

        [Option("sample-rate", Required = false, Default = 48000, HelpText = "The sampling frequency of the submitted audio (48000, 16000, 8000). Required if format is set to Linear16Pcm")]
            public int sampleRate { get; set; }



    }
}
