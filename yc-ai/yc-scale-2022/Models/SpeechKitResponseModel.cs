using Microsoft.EntityFrameworkCore.Metadata.Internal;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text;

namespace yc_scale_2022.Models
{
    [Table("asr_recognition")]
    public class SpeechKitResponseModel
    {
        [Key]
        public Guid RecognitionId { get; set; }
        public Guid SessionId { get; set; }
        public DateTime RecognitionDateTime { get; set; }

        public double? AudioLen { get; set; }

        [Column(TypeName = "varchar(100)")]
        public String TrackerKey { get; set; }
        
        [ForeignKey("AlternativeId")]
        public List<Alternative> Alternatives { get; set; }
        public bool Final { get; set; }
        public bool EndOfUtterance { get; set; }

        public SpeechKitResponseModel()
        {
            this.RecognitionId = Guid.NewGuid();
            this.RecognitionDateTime = DateTime.UtcNow; ;
        }

        public String GetWholeText()
        {
            StringBuilder sb = new StringBuilder();
            foreach (Alternative alt in this.Alternatives)
            {
                sb.AppendLine(alt.Text);
            }
            return sb.ToString();
        }
    }
    [Table("asr_alternative")] 
    public class Alternative
    {
        public Guid AlternativeId { get; set; }
        public Guid RecognitionId { get; set; }        
        public string Text { get; set; }
        public int Confidence { get; set; }

        [ForeignKey("AlternativeId")]
        public List<RecognizedWord> Words { get; set; }

        public Alternative()
        {
            this.AlternativeId = Guid.NewGuid();
        }
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

    [Table("asr_word")]
    public class RecognizedWord
    {
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Key]
        public int WordId { get; set; }
        public Guid AlternativeId { get; set; }
        [NotMapped]
        public StartTime StartTime { get; set; }
        [NotMapped]
        public EndTime EndTime { get; set; }
        
        public string Word { get; set; }
        public int Confidence { get; set; }
        
    }

}
