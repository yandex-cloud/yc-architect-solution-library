using System.ComponentModel.DataAnnotations;
using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace yc_scale_2022.Models
{
    public class SentimentsGrid
    {
        public Guid RecognitionId { get; set; }
        public DateTime StartDate { get; set; }
        public String RemoteIpAddress { get; set; }
        public double NoEmotion { get; set; }
        public double Joy { get; set; }
        public double Sadness { get; set; }
        public double Surprise { get; set; }
        public double Fear { get; set; }
        public double Anger { get; set;}
        public string Text { get; set; }

    }
}
