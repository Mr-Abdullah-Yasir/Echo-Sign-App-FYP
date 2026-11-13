$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$AssetsDir = Join-Path $ProjectRoot "assets"
$ModelName = "sherpa-onnx-streaming-zipformer-en-20M-2023-02-17"
$ModelDir = Join-Path $AssetsDir $ModelName
$Archive = Join-Path $ProjectRoot "$ModelName.tar.bz2"

$Url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/$ModelName.tar.bz2"

Write-Host "Creating assets folder..."
New-Item -ItemType Directory -Force -Path $AssetsDir | Out-Null

Write-Host "Downloading the SMALL sherpa-onnx English streaming ASR model..."
curl.exe -L $Url -o $Archive

if (-not (Test-Path $Archive)) {
    throw "Model download failed."
}

Write-Host "Extracting model..."
tar -xjf $Archive -C $AssetsDir

if (-not (Test-Path $ModelDir)) {
    throw "Model folder was not created after extraction."
}

$RequiredFiles = @(
    "encoder-epoch-99-avg-1.int8.onnx",
    "decoder-epoch-99-avg-1.onnx",
    "joiner-epoch-99-avg-1.int8.onnx",
    "tokens.txt"
)

foreach ($File in $RequiredFiles) {
    $FullPath = Join-Path $ModelDir $File
    if (-not (Test-Path $FullPath)) {
        throw "Required model file missing: $FullPath"
    }
}

Remove-Item $Archive -Force

Write-Host ""
Write-Host "Small offline ASR model installed successfully:"
Write-Host $ModelDir
Write-Host ""
Write-Host "Next run:"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter run"
