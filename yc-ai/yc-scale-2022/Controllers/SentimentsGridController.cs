using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using yc_scale_2022.Models;

namespace yc_scale_2022.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class SentimentsGridController : ControllerBase
    {


        private readonly ILogger<SentimentsGridController> _logger;
        private readonly ApplicationDbContext dbConn;
        public SentimentsGridController(ILogger<SentimentsGridController> logger, IConfiguration configuration)
        {
            this._logger = logger;
            this.dbConn = new ApplicationDbContext(configuration);
        }


        [HttpGet("{SessionId}")]
        public SentimentsGrid Get(String SessionId)
        {
            try { 
            var sentementStatQuery = (from resp in this.dbConn.AsrResponses                                     
                                      join inf in this.dbConn.MlInferences on resp.RecognitionId equals inf.recognition_id
                                      where resp.SessionId == Guid.Parse(SessionId) && resp.Final == true
                                      orderby resp.RecognitionDateTime descending
                                      select new SentimentsGrid()
                                      {
                                          RecognitionId = resp.RecognitionId,
                                          StartDate = resp.RecognitionDateTime,
                                          NoEmotion = inf.no_emotion,
                                          Joy = inf.joy,
                                          Sadness = inf.sadness,
                                          Surprise = inf.surprise,
                                          Fear = inf.fear,
                                          Anger = inf.anger,
                                          TrackerKey = resp.TrackerKey
                                      }).Take(1);

            return sentementStatQuery.FirstOrDefault();
            }
            catch (Exception ex)
            {
                this._logger.LogError($"{ex.Message}. Error reading SentimentsGrid for sesson {SessionId}");
                return null;
            }
        }

        [HttpGet]
        public IEnumerable<SentimentsGrid> Get()
        {
            String ip = HttpContext.Connection.RemoteIpAddress.ToString();
            try
            {
                
                var sentementStatQuery = (from ses in this.dbConn.AsrSessions
                                          join resp in this.dbConn.AsrResponses on ses.AsrSessionId equals resp.SessionId
                                          join alt in this.dbConn.AsrAletrnative on resp.RecognitionId equals alt.RecognitionId
                                          join inf in this.dbConn.MlInferences on resp.RecognitionId equals inf.recognition_id
                                          where ses.RemoteIpAddress == ip && resp.Final == true
                                          orderby resp.RecognitionDateTime descending
                                          select new SentimentsGrid()
                                          {
                                              RecognitionId = resp.RecognitionId,
                                              StartDate = resp.RecognitionDateTime,
                                              NoEmotion = inf.no_emotion,
                                              Joy = inf.joy,
                                              Sadness = inf.sadness,
                                              Surprise = inf.surprise,
                                              Fear = inf.fear,
                                              Anger = inf.anger,
                                              Text = alt.Text,
                                              TrackerKey = resp.TrackerKey
                                          }).Take(10);

                return sentementStatQuery.ToArray();
            }catch(Exception ex)
            {
                this._logger.LogError($"{ex.Message}. Error reading SentimentsGrid from {ip}");
                return null;
            }
        }
    }
}
