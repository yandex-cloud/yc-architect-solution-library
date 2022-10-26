using System;
using System.Collections.Generic;
using System.Text;

namespace ai.adoptionpack.speechkit.hybrid
{
    public class AudioDataEventArgs : EventArgs
    {
        public byte[] AudioData { get; private set; }


        private AudioDataEventArgs(int len)
        {
            AudioData = new byte[len];
        }

        public static AudioDataEventArgs FromByateArray(byte[] arBytes, int len)
        {
            AudioDataEventArgs retVal = new AudioDataEventArgs(len);
            Array.Copy(arBytes, retVal.AudioData, len);
            return retVal;
        }
    }
}
