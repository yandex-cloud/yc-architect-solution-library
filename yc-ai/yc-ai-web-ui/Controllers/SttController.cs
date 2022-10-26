using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using Microsoft.AspNetCore.Http;
using System.Threading.Tasks;
using yc.ai.webUI.Models;
using ai.adoptionpack.speechkit.hybrid.client;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace yc.ai.webUI.Controllers
{
  //  [Route("api/[controller]")]
    [ApiController]
    public class SttController : ControllerBase
    {
        [Route("api/message/send")]
        [HttpPost]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        
        public async Task<IActionResult> SttRequest(SttRequestModel model)
        {
            System.IO.MemoryStream ms = null;

            

            return Ok(File(ms, "audio/mpeg"));
        }
    }


}
