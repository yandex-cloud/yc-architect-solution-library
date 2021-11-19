using CommandLine;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Serilog;
using System;
using System.Collections.Generic;
using System.IO;
using vision.batch.classifier;

namespace vision.batch
{
    class VisionClient
    {
        public static IServiceProvider serviceProvider { get; private set; }

        static void Main(string[] args)
        {
            CommandLine.Parser.Default.ParseArguments<Configuration>(args)
              .WithParsed(RunOptions)
              .WithNotParsed(HandleParseError);
        }
        static void RunOptions(Configuration cfg)
        {
            serviceProvider = ConfigureServices(new ServiceCollection(), cfg);
            ILoggerFactory _loggerFactory = VisionClient.serviceProvider.GetService<ILoggerFactory>();
            _loggerFactory.AddSerilog();

            var logger = Log.Logger;
            try
            {
                if (cfg.mode.Equals(Mode.CLASSIFICATION) || cfg.mode.Equals(Mode.IMAGE_COPY_SEARCH))
                {
                    Log.Information($"Initiating {cfg.mode} call for {cfg.source}");
                    DoVisionClassification(cfg, _loggerFactory);
                }
               /* else if (cfg.mode.Equals(Mode.IMAGE_COPY_SEARCH))
                {
                    Log.Information($"Read tasks results from {cfg.tasksFile}");
                    DoTaskResults(cfg, _loggerFactory);
                }*/
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

        private static void DoVisionClassification(Configuration cfg, ILoggerFactory _loggerFactory)
        {

                VisionClassifier classifier = new VisionClassifier(cfg, _loggerFactory);
                List<ClassifyTaskModel> tasks = ClassifyTaskHelper.MakeVisionClassificationTasks(cfg);

                    classifier.Classify(tasks.ToArray());


        }

            private static IServiceProvider ConfigureServices(IServiceCollection services, Configuration Config)
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
}

