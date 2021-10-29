using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using Google.Protobuf;

namespace vision.batch.classifier
{
    public class ClassifyTaskModel
    {
        public string ImagePath { get; set; }
        public string TaskId { get; set; }

        internal ClassifyTaskModel(String ImagePath)
        {
            this.ImagePath = ImagePath;
            this.TaskId = Guid.NewGuid().ToString();
        }


        public string ImageType
        {
            get
            {
              return  Path.GetExtension(ImagePath);
            }
        }

        public string MimeType
        {
            get
            {
                if (ImageType.Equals(".jpeg", StringComparison.InvariantCultureIgnoreCase) 
                    || ImageType.Equals(".jpg", StringComparison.InvariantCultureIgnoreCase))
                {
                    return "image/jpeg";
                }
                else if (ImageType.Equals(".png", StringComparison.InvariantCultureIgnoreCase))
                {
                    return "image/png";
                }
                else
                    throw new ArgumentException($"Only jpeg or png images supported. Error processing {ImagePath}");

            }
        }

        public ByteString ContentBinaryString
        {
            get
            {
                return ByteString.CopyFrom(File.ReadAllBytes(ImagePath));
            }
        }

    }
}
