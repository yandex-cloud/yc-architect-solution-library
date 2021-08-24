# YC.SpeechKit.Streaming.Asr
<p>Yandex SpeechKit allows application developers to use Yandex speech technologies: speech recognition (Speech-to-Text) and speech synthesis (Text-to-Speech).</p>
<p>This is C# console demo application client for  streaming Speech To Text functionality</p>
<p>More information regarding  this service https://cloud.yandex.com/docs/speechkit/</p>
<p>Demo video: https://youtu.be/3j9-ZWP6bb4</p>
<h2> How to run <h2>
<ol>  
  <li>Register Yandex Cloud account and create folder in your tenant https://cloud.yandex.com/docs/resource-manager/operations/folder/create. Get id of your folder.</li>
  <li>Download and install .NET Core runtime for Win/Mac/Linux https://dotnet.microsoft.com/download</li>
  <li>Download, install and init Yandex Cloud Command Line interface tools https://cloud.yandex.com/docs/cli/quickstart#install</li>
  <li>Compile sources or download and unzip compiled client from Releases https://github.com/MaxKhlupnov/YC.SpeechKit.Streaming.Asr/releases</li>
  <li>Generate IaM token with command <code>yc iam create-token</code></li>
  <li>Prepare your audio in Ogg (Opus) or </li>
  <li>execute in command line:<code>dotnet YC.SpeechKit.Streaming.Asr.dll  --iam-token  your_iam_token --folder-id your_folder_id --in-file path_to_audio_file --audio-encoding your_file_encoding --sample-rate required_for_lpcm_only</code>
    <p>example for <a href='https://cloud.yandex.com/docs/speechkit/stt/formats#OggOpus'>ogg format</a>: <code>dotnet YC.SpeechKit.Streaming.Asr.dll  --iam-token t1.9eu.......A3YAA --folder-id  b1g95p77ivsq5c2vub3s --in-file="C:\PROJECTS\Yandex.Cloud\SpeechKit\DataSphere.ogg" --audio-encoding OggOpus</code></p>
    <p>example for <a href='https://cloud.yandex.com/docs/speechkit/stt/formats#lpcm'>lpcm format</a>: <code>dotnet YC.SpeechKit.Streaming.Asr.dll  --iam-token t1.9eu.......A3YAA --folder-id  b1g95p77ivsq5c2vub3s --in-file="C:\PROJECTS\Yandex.Cloud\SpeechKit\DataSphere.ogg" --audio-encoding Linear16Pcm  --sample-rate 16000</code></p> </li>
</ol>
  
