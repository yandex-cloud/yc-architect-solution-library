namespace yc_scale_2022.Models
{
    public class MlModelPayload
    {
        public string folder_id { get; set; }
        public string node_id { get; set; }
        public string data { get; set; }
    }

    public class MlInputTextPayload{
        public string text { get; set; }
    }

    public class EmotionsList
    {
        public double no_emotion { get; set; }
        public double joy { get; set; }
        public double sadness { get; set; }
        public double surprise { get; set; }
        public double fear { get; set; }
        public double anger { get; set; }
    }

    public class MlResponsePayload
    {
        public string recognition_id { get; set; }
        public string text { get; set; }
        public EmotionsList emotions_list { get; set; }
        public int words_count { get; set; }
        public string time { get; set; }
        public object name { get; set; }
    }
}
