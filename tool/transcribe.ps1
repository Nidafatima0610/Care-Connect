Add-Type -AssemblyName System.Speech
$engine = New-Object System.Speech.Recognition.SpeechRecognitionEngine
$engine.SetInputToWaveFile('C:\Users\umair\AppData\Local\Temp\user_voice.wav')
$grammar = New-Object System.Speech.Recognition.DictationGrammar
$engine.LoadGrammar($grammar)
$result = $engine.Recognize([TimeSpan]::FromSeconds(60))
if ($result) {
    Write-Output ("TRANSCRIPTION: " + $result.Text)
} else {
    Write-Output "No recognition result"
}
