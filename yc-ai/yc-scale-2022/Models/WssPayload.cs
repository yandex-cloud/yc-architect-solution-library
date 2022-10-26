using Speechkit.Stt.V3;
using System;

namespace yc_scale_2022.Models
{
    // Web Socker data structures
    public class WssPayload
    {
        public const string MSG_TYPE_CONNECT = "connect";

        public const string MSG_TYPE_DATA = "data";

        public const string MSG_TYPE_ERROR = "error";

        public const string MSG_TYPE_ML = "ml";
        public string type { get; set; }
        public string data { get; set; }
    }


    public class WssData
    {
        public Guid asr_event_id { get; set; }
        public StreamingResponse.EventOneofCase asr_event_type { get; set; }

        public string text { get; set; }
    }
}
