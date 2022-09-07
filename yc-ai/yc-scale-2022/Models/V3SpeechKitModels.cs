using System.Collections.Generic;

namespace yc_scale_2022.Models
{
    public class V3SpeechKitModels
    {

        // Root myDeserializedClass = JsonConvert.DeserializeObject<Root>(myJsonResponse);
        public class Alternative
        {
            public List<Word> Words { get; set; }
            public string Text { get; set; }
            public int StartTimeMs { get; set; }
            public int EndTimeMs { get; set; }
            public int Confidence { get; set; }
        }

        public class AudioCursors
        {
            public int ReceivedDataMs { get; set; }
            public int ResetTimeMs { get; set; }
            public int PartialTimeMs { get; set; }
            public int FinalTimeMs { get; set; }
            public int FinalIndex { get; set; }
            public int EouTimeMs { get; set; }
        }

        public class Final
        {
            public List<Alternative> Alternatives { get; set; }
            public string ChannelTag { get; set; }
        }

        public class FinalRefinement
        {
            public int FinalIndex { get; set; }
            public NormalizedText NormalizedText { get; set; }
            public int TypeCase { get; set; }
        }

        public class NormalizedText
        {
            public List<Alternative> Alternatives { get; set; }
            public string ChannelTag { get; set; }
        }

        public class Partial
        {
            public List<Alternative> Alternatives { get; set; }
            public string ChannelTag { get; set; }
        }

        public class Root
        {
            public SessionUuid SessionUuid { get; set; }
            public AudioCursors AudioCursors { get; set; }
            public int ResponseWallTimeMs { get; set; }
            public Partial Partial { get; set; }
            public Final Final { get; set; }
            public object EouUpdate { get; set; }
            public FinalRefinement FinalRefinement { get; set; }
            public object StatusCode { get; set; }
            public int EventCase { get; set; }
        }

        public class SessionUuid
        {
            public string Uuid { get; set; }
            public string UserRequestId { get; set; }
        }

        public class Word
        {
            public string Text { get; set; }
            public int StartTimeMs { get; set; }
            public int EndTimeMs { get; set; }
        }


    }
}
