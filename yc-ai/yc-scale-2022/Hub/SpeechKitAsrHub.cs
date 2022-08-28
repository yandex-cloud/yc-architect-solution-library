using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Logging;

namespace yc_scale_2022.Hub
{


    public class SpeechKitAsrHub : Hub<ISpeechKitClient>
    {
        private readonly ILogger<SpeechKitAsrHub> _logger;


        public SpeechKitAsrHub(ILogger<SpeechKitAsrHub> logger) : base()
        {
            this._logger = logger;
        }

        public async Task SendMessage(AsrMessage message)
        {
            await Clients.All.ReceiveMessage(message);
        }


    }
}
