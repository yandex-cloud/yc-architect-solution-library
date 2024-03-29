﻿using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace yc_scale_2022.Models
{

    public class MlInputModelPayload
    {
        public string folder_id { get; set; }
        public MlInput input { get; set; }
    }

    public class MlInput
    {
        public MlInputTextPayload input_data { get; set; }
    }

    public class MlInputTextPayload{
        public string text { get; set; }
    }

    [Table("ml_inference")]
    public class Inference
    {
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("InferenceId")]
        [Key]
        public int inference_id { get; set; }
        
        [Column("RecognitionId")]
        public Guid recognition_id { get; set; }
        
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
       
        [NotMapped]
        public string text { get; set; }
    }

    public class Output
    {
        public VoiceStat output { get; set; }
    }

    public class InferenceRoot
    {
        public Output output { get; set; }
    }

    public class VoiceStat
    {
        public string text { get; set; }
        public string time { get; set; }
        public int words_count { get; set; }
        public Inference emotions_list { get; set; }
        public object name { get; set; }
    }
}
