using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using CommandLine;

namespace vision.batch
{
    public class Configuration
    {
        [Option("mode", Required = true, Default = Mode.TEXT_DETECTION, HelpText = "Operation mode:  TEXT_DETECTION, CLASSIFICATION, FACE_DETECTION, IMAGE_COPY_SEARCH")]
        public Mode mode { get; set; }

        [Option("source", Required = true,  HelpText = "Path to sorce image file or directiry with files. JPEG, PNG PDF formats are supported")]
        public string source { get; set; }


        [Option("iam-token", Required = true, HelpText = "Specify the received IAM token when accessing Yandex.Cloud SpeechKit via the API.")]
        public string iamToken { get; set; }

        [Option("folder-id", Required = true, HelpText = "ID of the folder that you have access to.")]
        public String folderId { get; set; }


        [Option("model", Required = false, Default = "quality", HelpText = "required for CLASSIFICATION mode. Supported options are: quality and moderation")]
        public string model { get; set; }




    }

    public enum Mode
    {
        TEXT_DETECTION,
        CLASSIFICATION,
        FACE_DETECTION,
        IMAGE_COPY_SEARCH
    }
}
