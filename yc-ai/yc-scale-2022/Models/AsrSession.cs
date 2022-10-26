using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace yc_scale_2022.Models
{
    [Table("asr_sessions")]
    public class AsrSession
    {       
        [Key]
        public Guid AsrSessionId { get; set; }

        public DateTime StartDate { get; set; }

        public String TraceIdentifier { get; set; }
       
        [Column(TypeName = "varchar(255)")]
        public String UserAgent { get; set; }
        
        [Column(TypeName = "varchar(32)")]
        public String RemoteIpAddress { get; set; }

        public AsrSession()
        {
            StartDate = DateTime.UtcNow;
            AsrSessionId = Guid.NewGuid();
        }



    }
}
