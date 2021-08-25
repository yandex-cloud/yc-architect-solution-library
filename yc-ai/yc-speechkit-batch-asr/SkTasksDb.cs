
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Serilog;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace SkBatchAsrClient
{
    public class SkTaskDb : ISkTaskDb
    {

        private Dictionary<string, SkTaskModel> TaskDb { get; set; }


        public string TaskDbFilePath { get; private set; }

        public int Count => TaskDb.Count;

        public SkTaskModel[] Tasks => TaskDb.Values.ToArray<SkTaskModel>();

        ILogger log;

        public SkTaskDb(string taskDbFilePath, ILogger _loggerFactory)
        {
            TaskDb = new Dictionary<string, SkTaskModel>();
            log = _loggerFactory;
            this.TaskDbFilePath = taskDbFilePath;
            loadTasksDbFile();
        }

        public void storeTask(SkTaskModel recognitionTask)
        {

            if (!Exist(recognitionTask))
            {
                lock (TaskDb)
                {
                    using (StreamWriter sw = File.AppendText(this.TaskDbFilePath))
                    {
                        sw.WriteLine($"{recognitionTask.Path}; {recognitionTask.AudioUrl}; {recognitionTask.TaskId}");
                        TaskDb.Add(recognitionTask.Path, recognitionTask);
                        sw.Flush();
                    }
                }
            }
        }

        private void loadTasksDbFile()
        {   
            if ( !new FileInfo(this.TaskDbFilePath).Exists)
            {
                log.Warning($"Task file {this.TaskDbFilePath} not exists");
                return;
            }

            SkTaskModel[] tasks = File.ReadAllLines(this.TaskDbFilePath)
                .Select(SplitAndFill)
                .ToArray();

            foreach (SkTaskModel t in tasks)
                TaskDb.Add(t.Path, t);

        }

        public bool Exist(SkTaskModel recognitionTask)
        {
            return (TaskDb.ContainsKey(recognitionTask.Path));
        }


        private static SkTaskModel SplitAndFill(string line)
        {
            var sampleAlert = new SkTaskModel();

            var props = typeof(SkTaskModel).GetProperties();

            var values = line.Split(";");
            for (var i = 0; i < values.Length; i++)
            {
                props[i].SetValue(sampleAlert, values[i].Trim());
            }

            return sampleAlert;
        }


        public string StoreResults(dynamic jsonResponse, string bucketDir, SkTaskModel task)
        {
            string path = makeTaskPath(bucketDir, task);
            string taskDir = CheckDir(Path.GetDirectoryName(path));

            // write json
            string jsonFileName = makeJsonOutputFileName(bucketDir, task);
            File.WriteAllText(jsonFileName, jsonResponse.ToString(Formatting.Indented));

            // write text
            string txtFileName = makeTxtOutputFileName(bucketDir, task);
            File.WriteAllText(txtFileName, extractText((JObject)jsonResponse));

            log.Information($"Task id {task.TaskId} results succesfully stored at {jsonFileName}");
            return txtFileName;

        }

        private string makeTaskPath(string bucketDir, SkTaskModel task)
        {
            return bucketDir + '/' + task.Path;
        }

        private string makeTxtOutputFileName(string bucketDir, SkTaskModel task)
        {
            return Path.ChangeExtension(makeTaskPath(bucketDir, task), ".txt");
        }

        private string makeJsonOutputFileName(string bucketDir, SkTaskModel task)
        {
            return Path.ChangeExtension(makeTaskPath(bucketDir, task), ".json");
        }

        /**
         * Task is compleated if output file exists
         **/
        public bool CheckCompleated(string bucketDir, SkTaskModel task)
        {
            return File.Exists(makeTxtOutputFileName(bucketDir, task)) && File.Exists(makeJsonOutputFileName(bucketDir, task));
        }

        private string CheckDir(string path)
        {
            DirectoryInfo di = new DirectoryInfo(path);
            if (!di.Exists)
            {                
               return Directory.CreateDirectory(path).FullName;
            }
            return di.FullName;
        }


        private string extractText(JObject jsonResponse)
        {
            IEnumerable<JToken> chunks = jsonResponse.SelectTokens("response.chunks[*].alternatives[*].text");

            StringBuilder text = new StringBuilder();

            foreach(JToken chunk in chunks)
            {
                text.AppendLine(chunk.ToString());
            }

            return text.ToString();
      }
    }




    public interface ISkTaskDb
    {
      //  public void storeTask(SkTaskModel[] recognitionTask);
        public void storeTask(SkTaskModel recognitionTask);
        /// <summary>
        /// Return true if recognition task already stored
        /// </summary>
        /// <param name="recognitionTask"></param>
        public bool Exist(SkTaskModel recognitionTask);

        public SkTaskModel[] Tasks { get; }

        public int Count { get;}

        public bool CheckCompleated(string bucketDir, SkTaskModel task);
    }
}
