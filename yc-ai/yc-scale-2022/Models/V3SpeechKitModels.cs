using Serilog;
using Speechkit.Stt.V3;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Reflection.Metadata.Ecma335;
using System.Text;

namespace yc_scale_2022.Models
{
    public class V3SpeechKitModels
    {


        [Table("asr_recognition")]
        public class SpeechKitResponseModel
        {

            [Key]
            public Guid RecognitionId { get; set; }


            public Guid SessionId { get; set;}

            public DateTime RecognitionDateTime { get; set; }

            public double? AudioLen {
                get
                {
                    if (this.AudioCursors != null && AudioCursors.ReceivedDataMs > 0)
                        return AudioCursors.ReceivedDataMs / 1000;
                    else
                        return 0;
                }
                set
                {
                    // Do nothing
                }
            }


            [Column(TypeName = "varchar(100)")]
            public String TrackerKey { get; set; }


            [NotMapped]
            public bool IsFinal
            {
                get
                {

                    return EventCase == StreamingResponse.EventOneofCase.FinalRefinement;
                }
            }

            [ForeignKey("AlternativeId")]
            public List<Alternative> Alternatives
            {
                get
                {
                    if (this.FinalRefinement != null
                                        && this.FinalRefinement.NormalizedText != null
                                                && this.FinalRefinement.NormalizedText.Alternatives != null)
                        return this.FinalRefinement.NormalizedText.Alternatives;
                    else if (this.Final != null &&
                                            this.Final.Alternatives != null)
                        return this.Final.Alternatives;
                    else if (this.Partial != null && this.Partial.Alternatives != null)
                        return this.Partial.Alternatives;

                    Log.Error($"No alternative data found for {this.EventCase} in speechkit SessionId {this.SessionId} RequestId {this.RecognitionId}");
                    return null;

                }
                set
                {

                }
            }


            public SessionUuid SessionUuid { get; set; }
            
            [NotMapped]
            public AudioCursors AudioCursors { get; set; }
            
            [NotMapped]
            public int ResponseWallTimeMs { get; set; }
            
            [NotMapped] 
            public Partial Partial { get; set; }
            
            [NotMapped]
            public Final Final { get; set; }
            
            [NotMapped] 
            public object EouUpdate { get; set; }

            [NotMapped]
            public FinalRefinement FinalRefinement { get; set; }
            [NotMapped]
            public object StatusCode { get; set; }

            public StreamingResponse.EventOneofCase EventCase { get; set; }

            public String GetWholeText()
            {
                StringBuilder sb = new StringBuilder();
                foreach (Alternative alt in this.Alternatives)
                {
                    sb.AppendLine(alt.Text);
                }
                return sb.ToString();
            }

            public SpeechKitResponseModel()
            {             
                this.RecognitionDateTime = DateTime.UtcNow;
                this.RecognitionId = Guid.NewGuid();
            }

        }

        [Table("asr_alternative")]
        public class Alternative
        {
            public Guid AlternativeId { get; set; }
            public Guid RecognitionId { get; set; }
            public List<Word> Words { get; set; }
            public string Text { get; set; }
            public int StartTimeMs { get; set; }
            public int EndTimeMs { get; set; }
            public int Confidence { get; set; }

            public Alternative()
            {
                this.AlternativeId = Guid.NewGuid();
            }
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

        [Table("asr_speechkit_session_ids")]
        public class SessionUuid
        {
            [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
            [Key]
            public int SpeechKitSessionId { get; set; }

            [Column(TypeName = "varchar(50)")]
            public string Uuid { get; set; }
            [Column(TypeName = "varchar(50)")]
            public string UserRequestId { get; set; }
        }
        
        [Table("asr_word")]
        public class Word
        {
            [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
            [Key]
            public int WordId { get; set; }
            public Guid AlternativeId { get; set; }
            public string Text { get; set; }
            public int StartTimeMs { get; set; }
            public int EndTimeMs { get; set; }
        }


    }
}
