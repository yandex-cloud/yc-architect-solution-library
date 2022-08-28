namespace yc_scale_2022.Models
{
    public class WssPayload
    {
        public const string MSG_TYPE_CONNECT = "connect";

        public const string MSG_TYPE_DATA = "data";

        public const string MSG_TYPE_ERROR = "error"; 
        public string type { get; set; }
        public string data { get; set; }
    }
}
