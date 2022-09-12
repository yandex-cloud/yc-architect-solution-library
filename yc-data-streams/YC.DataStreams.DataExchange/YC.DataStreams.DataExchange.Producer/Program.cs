using Amazon.Kinesis;
using Amazon.Kinesis.Model;
using Microsoft.Extensions.Configuration;
using System.Text;
using System.Text.Json;
using YC.DataStreams.DataExchange.Shared;

namespace YC.DataStreams.DataExchange.Producer
{
    internal class Program
    {
        static string YC_Key_ID;
        static string YC_Key_secret;
        static string streamPath;
        static AmazonKinesisConfig config;

        static int _publishInterval = 5000;
        static bool _cancelled = false;

        static void Main(string[] args)
        {
            var YCConfiguration = new ConfigurationBuilder().AddJsonFile("appsettings.json").Build().GetSection("YandexCloudDataStreamConfiguration");
            streamPath = $"/{YCConfiguration["region"]}/{YCConfiguration["folder"]}/{YCConfiguration["database"]}/{YCConfiguration["streamName"]}";
            Console.CancelKeyPress += new ConsoleCancelEventHandler(Console_CancelKeyPress);
            YC_Key_ID = YCConfiguration["YC_Key_ID"];
            YC_Key_secret = YCConfiguration["YC_Key_secret"];

            config = new AmazonKinesisConfig()
            {
                ServiceURL = YCConfiguration["serviceURL"],
                AuthenticationRegion = YCConfiguration["region"]
            };

            Console.WriteLine($"Now ready to produce data into Kinesis stream: {streamPath}\n");
            Console.WriteLine("Press Ctrl+C to exit...\n");


            while (!_cancelled)
            {
                List<DeviceData> dataList = DeviceData.RandomDeviceList();
                Produce(dataList);
                Thread.Sleep(_publishInterval);
            }

            Console.WriteLine("Task Completed!\n");
            Console.Write("To publish more data, please run the application again.\n");

            Console.CancelKeyPress -= new ConsoleCancelEventHandler(Console_CancelKeyPress);
        }
        private static void Produce(List<DeviceData> dataList)
        {
            var kinesisClient = new AmazonKinesisClient(YC_Key_ID, YC_Key_secret, config);
            foreach (DeviceData data in dataList)
            {
                var dataAsJson = JsonSerializer.Serialize(data);
                var dataAsBytes = Encoding.UTF8.GetBytes(dataAsJson);
                using (var memoryStream = new MemoryStream(dataAsBytes))
                {
                    try
                    {
                        var requestRecord = new PutRecordRequest
                        {
                            StreamName = streamPath,
                            PartitionKey = "1", // Ключ сегмента. // https://cloud.yandex.ru/docs/data-streams/concepts/partition-keys
                            Data = memoryStream
                        };
                        var responseRecord = kinesisClient.PutRecordAsync(requestRecord).Result;
                        Console.WriteLine($"Successfully published Record:{data.DeviceId},{data.Humidity},{data.Temperature} Seq:{responseRecord.SequenceNumber}");
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Failed to publish. Exception: {ex.Message}");
                    }
                }
            }
        }

        private static void Console_CancelKeyPress(object sender, ConsoleCancelEventArgs e)
        {
            if (e.SpecialKey == ConsoleSpecialKey.ControlC)
            {
                _cancelled = true;
                e.Cancel = true;
            }
        }
    }
}