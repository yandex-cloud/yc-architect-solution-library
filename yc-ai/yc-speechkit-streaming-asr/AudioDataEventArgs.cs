using System;
using System.Collections.Generic;
using System.Text;

namespace YC.SpeechKit.Streaming.Asr
{
    public class AudioDataEventArgs : EventArgs
    {
        public byte[] AudioData { get; private set; }


        private AudioDataEventArgs(int len)
        {
            AudioData = new byte[len];
        }

        internal static AudioDataEventArgs FromByateArray(byte[] arBytes, int len)
        {
            AudioDataEventArgs retVal = new AudioDataEventArgs(len);
            Array.Copy(arBytes, retVal.AudioData, len);
            return retVal;
        }
    }
}
