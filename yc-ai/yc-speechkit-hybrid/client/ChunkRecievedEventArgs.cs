using System;
using System.Text.Json;
using System.Collections.Generic;
using System.Text;
using Speechkit.Stt.V3;
using System.Xml;
using System.IO;

namespace ai.adoptionpack.speechkit.hybrid.client
{
    /**
    * Speech recognition results event
    */
    public class ChunkRecievedEventArgs : EventArgs
    {
        public AlternativeUpdate SpeechToTextChunk { get; private set; }
        public StreamingResponse.EventOneofCase EventCase { get; private set; }

        internal ChunkRecievedEventArgs(AlternativeUpdate chunk, StreamingResponse.EventOneofCase eventCase)
        {
            this.SpeechToTextChunk = chunk;
            this.EventCase = eventCase;
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
