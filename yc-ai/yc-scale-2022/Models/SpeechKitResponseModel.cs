using System.Collections.Generic;

namespace yc_scale_2022.Models
{

     public class SpeechKitResponseModel
    {
        public List<Alternative> Alternatives { get; set; }
        public bool Final { get; set; }
        public bool EndOfUtterance { get; set; }
    }

    public class Alternative
    {
        public string Text { get; set; }
        public int Confidence { get; set; }
        public List<Word> Words { get; set; }
    }

    public class EndTime
    {
        public int Seconds { get; set; }
        public int Nanos { get; set; }
    }


    public class StartTime
    {
        public int Seconds { get; set; }
        public int Nanos { get; set; }
    }

    public class Word
    {
        public StartTime StartTime { get; set; }
        public EndTime EndTime { get; set; }
        public string word { get; set; }
        public int Confidence { get; set; }
    }

}
