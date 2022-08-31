﻿using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

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

    [Table("ml_inference")]
    public class EmotionsList
    {
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("InferenceId")]
        [Key]
        public int inference_id { get; set; }
        
        [Column("RecognitionId")]
        public string recognition_id { get; set; }
        
        [Column("NoEmotion")]
        public double no_emotion { get; set; }
        
        [Column("Joy")]
        public double joy { get; set; }
        
        [Column("Sadness")]
        public double sadness { get; set; }
        [Column("Surprise")]
        public double surprise { get; set; }
        
        [Column("Fear")]
        public double fear { get; set; }
        [Column("Anger")]
        public double anger { get; set; }
    }

    public class MlResponsePayload
    {        
        public string text { get; set; }
        public EmotionsList emotions_list { get; set; }
        public int words_count { get; set; }
        public string time { get; set; }
        public object name { get; set; }
    }
}