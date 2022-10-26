using Amazon.Kinesis;
using Amazon.Kinesis.Model;
using Microsoft.Extensions.Configuration;
using System.Text;

namespace YC.DataStreams.DataExchange.Consumer
{
    internal class Program
    {
        static string YC_Key_ID;
        static string YC_Key_secret;
        static string streamPath;
        static AmazonKinesisConfig config;
        static AmazonKinesisClient kinesisClient;

        static bool _cancelled = false;
        static async Task Main(string[] args)
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
            kinesisClient = new AmazonKinesisClient(YC_Key_ID, YC_Key_secret, config);
            var describeRequest = new DescribeStreamRequest
            {
                StreamName = streamPath
            };
            var responces = await kinesisClient.DescribeStreamAsync(describeRequest);
            var shards = responces.StreamDescription.Shards;
            string shardNext = string.Empty;

            Console.CancelKeyPress += new ConsoleCancelEventHandler(Console_CancelKeyPress);

            Console.WriteLine($"Now ready to consume data from Kinesis stream: {streamPath}\n");
            Console.WriteLine("Press Ctrl+C to exit...\n");

            foreach (var shard in shards)
            {
                await foreach (var record in Consume(shard))
                {
                    var dataAsBytes = record.Data.ToArray();
                    var dataAsString = Encoding.UTF8.GetString(dataAsBytes);
                    var info = $"Seq:{record.SequenceNumber} {dataAsString}";
                    Console.WriteLine(info);
                    if (_cancelled == true)
                    {
                        break;
                    }
                }
            }

            Console.WriteLine("Task Completed!\n");
            Console.Write("To publish more data, please run the application again.\n");

            Console.CancelKeyPress -= new ConsoleCancelEventHandler(Console_CancelKeyPress);
        }

        private static async IAsyncEnumerable<Record> Consume(Shard shard)
        {
            var getShardIteratorRequest = new GetShardIteratorRequest()
            {
                StreamName = streamPath,
                ShardId = shard.ShardId,
                ShardIteratorType = "LATEST" // https://docs.aws.amazon.com/sdkfornet1/latest/apidocs/html/P_Amazon_Kinesis_Model_GetShardIteratorRequest_ShardIteratorType.htm          
            };
            var getShardIteratorResponce = kinesisClient.GetShardIteratorAsync(getShardIteratorRequest).Result;
            var getRequest = new GetRecordsRequest()
            {
                ShardIterator = getShardIteratorResponce.ShardIterator
            };
            while (true)
            {
                var getRecordsResponce = kinesisClient.GetRecordsAsync(getRequest).Result;
                foreach (var record in getRecordsResponce.Records)
                {
                    yield return record;
                }
                getRequest.ShardIterator = getRecordsResponce.NextShardIterator;
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