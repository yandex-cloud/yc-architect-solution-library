using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Net.Http;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using yc_scale_2022.Models;
using System.Text.Json;
using System.Text;

namespace yc_scale_2022
{
    public class TrackerProcessor
    {
        private ILogger logger;
        private IConfiguration configuration;
        private HttpClient _httpClient;

        public TrackerProcessor(IConfiguration configuration, ILogger logger)
        {
            this.configuration = configuration;
            this.logger = logger;
            this._httpClient = new HttpClient();

            _httpClient.DefaultRequestHeaders.Add("X-Org-ID", "6935533");
            _httpClient.DefaultRequestHeaders.Authorization =
                                new System.Net.Http.Headers.AuthenticationHeaderValue("OAuth", "y0_AgAAAABkVZ7GAAhihgAAAADN_8ulLuf0Vv2qTTGn7sylnWvgObF57pQ");
        }

        public async Task<string> CreateTiket(SpeechKitResponseModel responseModel, Inference mlInference)
        {



            TrackerPayloadModel trackerPayload = new TrackerPayloadModel();
            trackerPayload.queue.key = "SCALE";
            trackerPayload.summary = responseModel.GetWholeText();
            trackerPayload.tags = trackerPayload.osnovnaaEmocia = FormatMainEmotion(mlInference);
            trackerPayload.boards = 2;
            trackerPayload.assignee = "scale2022";


            String node_id = this.configuration["MlNodeId"]; // datashpere node id
            String ml_api_key = this.configuration["MlApiKey"]; // datashpere api key


            String url = $"https://api.tracker.yandex.net/v2/issues/";

            

            HttpResponseMessage httpResponse = await _httpClient.PostAsync(url,
                                    new StringContent(JsonSerializer.Serialize(trackerPayload), Encoding.UTF8, "application/json"));
            if (httpResponse.StatusCode == System.Net.HttpStatusCode.Created)
            {
                String respJsonPayLoad = await httpResponse.Content.ReadAsStringAsync();

                try
                {
                    TrackerResponseModel trackerOutput = JsonSerializer.Deserialize<TrackerResponseModel>(respJsonPayLoad);


                    this.logger.LogTrace($"session {responseModel.RecognitionId}  tracker key {trackerOutput.key}");

                    return trackerOutput.key;

                }
                catch (Exception e)
                {
                    logger.LogError($"Error parsing rest {url} response {e} for asr response {responseModel.RecognitionId}.");
                }
            }
            else
            {
                logger.LogError($"Http error {httpResponse.StatusCode} calling {url} for asr response {responseModel.RecognitionId}..");

            }
            return null;
        }


        private static String FormatMainEmotion(Inference mlInference)
        {
            Dictionary<string, double> emoutionsDict = new Dictionary<string, double>();
            emoutionsDict.Add("Без эмоции", mlInference.no_emotion);
            emoutionsDict.Add("Грусть", mlInference.sadness);
            emoutionsDict.Add("Радость", mlInference.joy);
            emoutionsDict.Add("Злость", mlInference.anger);
            emoutionsDict.Add("Страх", mlInference.fear);
            emoutionsDict.Add("Удивление", mlInference.surprise);

            double mainEmoution = emoutionsDict.Values.Max();
            return emoutionsDict.FirstOrDefault(v => v.Value == mainEmoution).Key;


        }
    }

}
