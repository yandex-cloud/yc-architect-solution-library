using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace vision.batch.classifier
{
    public static class ClassifyTaskHelper
    {

        public static List<ClassifyTaskModel> MakeVisionClassificationTasks(Configuration cfg)
        {
            List<ClassifyTaskModel> taskList = new List<ClassifyTaskModel>();
            if (IsFolderSource(cfg.source))
            {
                MakeDirectoryTasks(cfg.source, ref taskList);
            }
            else
            {
                taskList.Add(new ClassifyTaskModel(cfg.source));
            }
            return taskList;
        }


        private static void MakeDirectoryTasks(string dir, ref List<ClassifyTaskModel> taskList)
        {
            var imageFiles = Directory.GetFiles(dir, "*.*")
                    .Where(file => file.ToLower().EndsWith("jpg") || file.ToLower().EndsWith("jpeg") || file.ToLower().EndsWith("png"))
                    .ToArray();

            foreach (string fileName in imageFiles)
            {
                taskList.Add(new ClassifyTaskModel(fileName));
            }
            foreach (string dirName in Directory.GetDirectories(dir))
            {
                MakeDirectoryTasks(dirName, ref taskList);
            }
        }

        private static bool IsFolderSource(String source)
        {

                return (File.GetAttributes(source) & FileAttributes.Directory) == FileAttributes.Directory;

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
