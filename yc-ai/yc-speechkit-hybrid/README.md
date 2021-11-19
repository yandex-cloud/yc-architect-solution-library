# ai.adoptionpack.speechkit.hybrid
<p>Yandex SpeechKit allows application developers to use Yandex speech technologies on prem: speech recognition (Speech-to-Text) and speech synthesis (Text-to-Speech).</p>
<p>This is C# console demo application client for  streaming Speech To Text functionality</p>
<p>More information regarding  this service https://cloud.yandex.com/en-ru/docs/speechkit/hybrid-speechkit/conception </p>

<h2> How to run </h2>
<ol>  
  <li>Download and install .NET Core runtime for Win/Mac/Linux https://dotnet.microsoft.com/download </li>
  <li>Download, install and init Yandex Cloud Command Line interface tools https://cloud.yandex.com/docs/cli/quickstart#install</li>
  <li>Compile sources or download and unzip compiled client or download container</li>
  <li>Generate IaM token with command <code>yc iam create-token</code></li>
  <li>Prepare your audio in Ogg (Opus) or Wav audio source file.
    <p>input audio must be <a href='https://cloud.yandex.com/docs/speechkit/stt/formats#lpcm'> in supported format</a></p>
  </li>
  <li>command line example:
     <p><code>dotnet ai.adoptionpack.speechkit.hybrid.dll  --service-uri="http://your-speechkit-hybrid-endpoint:8080" --in-file="path_to your_input.wav" --mode=stt --audio-format Wav</code></p>
     <p><code>dotnet ai.adoptionpack.speechkit.hybrid.dll  --service-uri="http://your-speechkit-hybrid-endpoint:8080" --in-file="path_to your_input.ogg" --mode=stt --audio-format OggOpus</code></p>
    </li>
</ol>
  
