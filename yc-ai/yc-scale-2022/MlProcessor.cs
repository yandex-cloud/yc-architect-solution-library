using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System;
using yc_scale_2022.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Text.Json;

namespace yc_scale_2022
{
    public class MlProcessor
    {
        private ILogger logger;        
        private IConfiguration configuration;
        private HttpClient _httpClient;

        public MlProcessor(IConfiguration configuration, ILogger logger) {
            this.configuration = configuration;
            this.logger = logger;
            this._httpClient = new HttpClient();

            String ml_api_key = this.configuration["MlApiKey"]; // datashpere api key
            _httpClient.DefaultRequestHeaders.Add("Host", "datasphere.api.cloud.yandex.net");

            _httpClient.DefaultRequestHeaders.Authorization =
                                new System.Net.Http.Headers.AuthenticationHeaderValue("Api-Key", ml_api_key);
        }

        public async Task<Inference> SentimentAnalysis(SpeechKitResponseModel responseModel)
        {

                
                MlInput mlInTextPayload = new MlInput()
                {
                    input_data = new MlInputTextPayload() { 
                        text = responseModel.GetWholeText() 
                    }
                };
                // string mlInJsonPayload = JsonSerializer.Serialize(mlInTextPayload);

                String node_id = this.configuration["MlNodeId"]; // datashpere node id              


                String url = $"https://datasphere.api.cloud.yandex.net/datasphere/v1/nodes/{node_id}:execute";

        

                MlInputModelPayload mlPayload = new MlInputModelPayload()
                {
                    folder_id = this.configuration["MlFolderId"], ///datashpere folder id
                    input = mlInTextPayload
                };

                HttpResponseMessage httpResponse = await _httpClient.PostAsync(url,
                                    new StringContent(JsonSerializer.Serialize(mlPayload), Encoding.UTF8, "application/json"));
                if (httpResponse.StatusCode == System.Net.HttpStatusCode.OK)
                {
                    String respJsonPayLoad = await httpResponse.Content.ReadAsStringAsync();

                    try
                    {
                        InferenceRoot mlOutput = JsonSerializer.Deserialize<InferenceRoot>(respJsonPayLoad);

                        mlOutput.output.voice_stat.emotions_list.recognition_id = responseModel.RecognitionId;
                    
                        this.logger.LogTrace($"session {responseModel.SessionId}  model inference recieved for asr response {responseModel.RecognitionId}..");

                        return mlOutput.output.voice_stat.emotions_list;                                               

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
    }
}
