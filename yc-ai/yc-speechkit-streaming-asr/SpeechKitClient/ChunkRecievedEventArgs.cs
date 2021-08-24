using System;
using System.Text.Json;
using System.Collections.Generic;
using System.Text;
using Yandex.Cloud.Ai.Stt.V2;
using System.Xml;
using System.IO;

namespace YC.SpeechKit.Streaming.Asr.SpeechKitClient
{
    /**
    * Speech recognition results event
    */
    public class ChunkRecievedEventArgs : EventArgs
    {
        public SpeechRecognitionChunk SpeechToTextChunk{ get; private set; }

        internal ChunkRecievedEventArgs(SpeechRecognitionChunk chunk)
        {
            this.SpeechToTextChunk = chunk;
        }

   
        public string AsJson()
        {
            var options = new JsonSerializerOptions
            {
                Encoder = System.Text.Encodings.Web.JavaScriptEncoder.Create(System.Text.Unicode.UnicodeRanges.All),
                WriteIndented = true
            };
            byte[] jsonUtf8Bytes;
            jsonUtf8Bytes = JsonSerializer.SerializeToUtf8Bytes(this.SpeechToTextChunk, options);
           return System.Text.Encoding.UTF8.GetString(jsonUtf8Bytes);
        }
    }
}
