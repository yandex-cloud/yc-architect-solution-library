using System;
using System.IO;
using System.Threading;
using System.Collections.Generic;
using System.Text;
using Serilog;
using System.Threading.Tasks;

namespace YC.SpeechKit.Streaming.Asr
{
    public class FileStreamReader
    {

        internal const int BUFFER_SIZE = 32 * 1024;

        private String filePath;

        public event EventHandler<AudioDataEventArgs> AudioBinaryRecived;

        private Serilog.ILogger log;
        public FileStreamReader(String filePath)

        {
            this.log = Log.Logger;
            this.filePath = filePath;
        }

        public Task ReadAudioFile()
        {
            return Task.Factory.StartNew(() =>
            {
                using (FileStream fs = File.Open(this.filePath, FileMode.Open))
                {
                    using (BufferedStream bs = new BufferedStream(fs, BUFFER_SIZE))
                    {
                        int byteRead;
                        byte[] buffer = new byte[BUFFER_SIZE];

                        while ((byteRead = bs.Read(buffer, 0, BUFFER_SIZE)) > 0)
                        {
                            AudioBinaryRecived?.Invoke(this, AudioDataEventArgs.FromByateArray(buffer, byteRead));
                            log.Information($"{byteRead} bytes read from {filePath}");
                            Thread.Sleep(1000);
                        }
                    }
                }
                log.Information($"File data sent");
            });
        }
    }
}
