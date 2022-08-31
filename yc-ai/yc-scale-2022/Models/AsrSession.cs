using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace yc_scale_2022.Models
{
    [Table("asr_sessions")]
    public class AsrSession
    {
        public DateTime StartDate { get; set; }
        [Key]
        public Guid AsrSessionId { get; set; }
        public String TraceIdentifier { get; set; }

        public String UserAgent { get; set; }

        public String RemoteIpAddress { get; set; }

        public AsrSession()
        {
            AsrSessionId = Guid.NewGuid();
            StartDate = DateTime.UtcNow;
        }



    }
}
