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
        public StreamingResponse SpeechToTextChunk { get; private set; }
        public StreamingResponse.EventOneofCase EventCase { 
            get { return SpeechToTextChunk.EventCase;  } 
        }

        internal ChunkRecievedEventArgs(StreamingResponse eventResponse)
        {
            this.SpeechToTextChunk = eventResponse;
        }


        public string AsJson(bool writeIndented)
        {
            var options = new JsonSerializerOptions
            {
                Encoder = System.Text.Encodings.Web.JavaScriptEncoder.Create(System.Text.Unicode.UnicodeRanges.All),
                WriteIndented = writeIndented
            };
            byte[] jsonUtf8Bytes;
            jsonUtf8Bytes = JsonSerializer.SerializeToUtf8Bytes(this.SpeechToTextChunk, options);
           return System.Text.Encoding.UTF8.GetString(jsonUtf8Bytes);
        }
    }
}
