using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;

using yc.ai.webUI.Models;
using ai.adoptionpack.speechkit.hybrid.client;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace yc.ai.webUI.Controllers
{

    [ApiController]
    public class TtsController : ControllerBase
    {

        private readonly ILogger<TtsController> _logger;

        public TtsController(ILogger<TtsController> logger) : base()
        {
            this._logger = logger;
        }

        [Route("api/tts/synth")]
        [HttpPost]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]

        public async Task<IActionResult> TtsRequest(TtsRequestModel model)
        {
            System.IO.MemoryStream ms = null;

            //SpeechKitTtsClient TtsClient = new SpeechKitTtsClient(model.serviceUri, null, null, logger);

            return Ok(File(ms, "audio/mpeg"));
        }
    }
}
