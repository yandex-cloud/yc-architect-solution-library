namespace yc_scale_2022.Models
{
    public class AudioStreamFormat
    {
        public string language { get; set; } 
        public string format { get; set; }
        public int sampleRate { get; set; }

        /*  Must match RecognitionSpec.Types.AudioEncoding */
        public string getAudioEncoding()
        {
            if (this.format.Contains("pcm"))
            {
                return "Linear16Pcm";
            }
            else if (this.format.Contains("ogg"))
            {
                return "OggOpus";
            }
            else
            {
                return this.format;
            };
        }
    }
}
