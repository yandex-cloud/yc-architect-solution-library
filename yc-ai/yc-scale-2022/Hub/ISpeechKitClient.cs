using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace yc_scale_2022.Hub
{
    public interface ISpeechKitClient

    {
        Task ReceiveMessage(AsrMessage message);
    }
}
