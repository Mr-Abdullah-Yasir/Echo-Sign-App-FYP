$ErrorActionPreference = "Stop"
Write-Host "EchoSign Pro - whisper_ggml Android compileSdk patch" -ForegroundColor Cyan

if ($env:PUB_CACHE -and (Test-Path $env:PUB_CACHE)) {
    $pubCache = $env:PUB_CACHE
} else {
    $pubCache = Join-Path $env:LOCALAPPDATA "Pub\Cache"
}

$hostedRoot = Join-Path $pubCache "hosted"
if (-not (Test-Path $hostedRoot)) {
    throw "Pub hosted cache not found. Run flutter pub get first."
}

$pkgDirs = Get-ChildItem -Path $hostedRoot -Directory -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "whisper_ggml-*" } |
    Sort-Object LastWriteTime -Descending

if (-not $pkgDirs) {
    throw "Could not find whisper_ggml in PUB_CACHE."
}

$pkg = $pkgDirs | Select-Object -First 1
Write-Host "Found package: $($pkg.FullName)" -ForegroundColor Green

$candidates = @(
    (Join-Path $pkg.FullName "android\build.gradle"),
    (Join-Path $pkg.FullName "android\build.gradle.kts")
)

$gradleFile = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $gradleFile) {
    throw "Could not find whisper_ggml Android Gradle file."
}

$content = Get-Content -Path $gradleFile -Raw
$original = $content

$content = $content -replace '(?m)^\s*compileSdkVersion\s+34\s*$', '    compileSdkVersion 35'
$content = $content -replace '(?m)^\s*compileSdk\s+34\s*$', '    compileSdk 35'
$content = $content -replace '(?m)^\s*compileSdkVersion\s*=\s*34\s*$', '    compileSdkVersion = 35'
$content = $content -replace '(?m)^\s*compileSdk\s*=\s*34\s*$', '    compileSdk = 35'

if ($content -eq $original) {
    Select-String -Path $gradleFile -Pattern "compileSdk|ndkVersion" -Context 1,1
    throw "Automatic patch did not apply. Send the displayed lines to ChatGPT."
}

Copy-Item $gradleFile "$gradleFile.bak_echosign" -Force
Set-Content -Path $gradleFile -Value $content -Encoding UTF8

Write-Host "Patch applied successfully." -ForegroundColor Green
Write-Host "Now run:"
Write-Host "flutter clean"
Write-Host "flutter pub get"
Write-Host "flutter run"
