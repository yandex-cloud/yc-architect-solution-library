using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace ai.adoptionpack.speechkit.hybrid
{
    public static class Helpers
    {

        public static string extractText(string json, String jsonPath)
        {

            dynamic jsonResponse = JObject.Parse(json);

            IEnumerable<JToken> chunks = jsonResponse.SelectTokens(jsonPath);

            StringBuilder text = new StringBuilder();

            foreach (JToken chunk in chunks)
            {
                text.AppendLine(chunk.ToString());
            }

            return text.ToString();
        }
        public static IEnumerable<IEnumerable<T>> Batch<T>(this IEnumerable<T> collection, int batchSize)
        {
            var nextbatch = new List<T>(batchSize);
            foreach (T item in collection)
            {
                nextbatch.Add(item);
                if (nextbatch.Count == batchSize)
                {
                    yield return nextbatch;
                    nextbatch = new List<T>(batchSize);
                }
            }

            if (nextbatch.Count > 0)
            {
                yield return nextbatch;
            }
        }

    }
}
