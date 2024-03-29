﻿using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Net.Http;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using yc_scale_2022.Models;
using System.Text.Json;
using System.Text;
using SpeechKitResponseModel = yc_scale_2022.Models.V3SpeechKitModels.SpeechKitResponseModel;
using System.Text.Encodings.Web;
using System.Text.Unicode;

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

            _httpClient.DefaultRequestHeaders.Add("X-Org-ID", configuration["X-Org-ID"]);
            _httpClient.DefaultRequestHeaders.Authorization =
                                new System.Net.Http.Headers.AuthenticationHeaderValue("OAuth", configuration["TrackerOAuth"]);
        }

        public async Task<string> CreateTiket(SpeechKitResponseModel responseModel, Inference mlInference)
        {

            TrackerPayloadModel trackerPayload = new TrackerPayloadModel();
            trackerPayload.queue.key = "SCALE";
            string text = responseModel.GetWholeText();
            trackerPayload.summary = text.Length > 50 ? text.Substring(0, 50) : text;
            trackerPayload.description = text.Length > 50 ? text : "";

            trackerPayload.tags = trackerPayload.osnovnaaEmocia = FormatMainEmotion(mlInference);
            trackerPayload.boards = 2;
            trackerPayload.assignee = "scale2022";

            String url = $"https://api.tracker.yandex.net/v2/issues/";

            var options = new JsonSerializerOptions
            {
                Encoder = JavaScriptEncoder.Create(UnicodeRanges.BasicLatin, UnicodeRanges.Cyrillic),
                WriteIndented = false
            };

            HttpResponseMessage httpResponse = await _httpClient.PostAsync(url,
                                    new StringContent(JsonSerializer.Serialize(trackerPayload, options), Encoding.UTF8, "application/json"));
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
            emoutionsDict.Add("Без эмоций", mlInference.no_emotion);
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
