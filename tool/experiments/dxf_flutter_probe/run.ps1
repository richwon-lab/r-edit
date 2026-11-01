[CmdletBinding()]
param([ValidateSet('get','analyze','test','windows-test','build','run')][string]$Action='run')
$ErrorActionPreference='Stop'
$repository=Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
$flutter=Join-Path $repository '.fvm/flutter_sdk/bin/flutter.bat'
if(!(Test-Path -LiteralPath $flutter)){throw '먼저 앱의 고정 FVM SDK 3.47.7을 준비하세요. 전역 SDK로 대체하지 않습니다.'}
$previousCache=$env:PUB_CACHE
try {
 $env:PUB_CACHE=Join-Path $repository '.tooling/pub-cache'
 Push-Location $PSScriptRoot
 try {
  switch($Action){
   'get' { & $flutter pub get }
   'analyze' { & $flutter analyze --fatal-infos }
   'test' { & $flutter test test/probe_contract_test.dart }
   'windows-test' { & $flutter test integration_test/probe_windows_test.dart -d windows }
   'build' { & $flutter build windows --debug }
   'run' { & $flutter run -d windows }
  }
  if($LASTEXITCODE -ne 0){throw "격리 실험 명령 실패: $Action ($LASTEXITCODE)"}
 } finally {Pop-Location}
} finally {$env:PUB_CACHE=$previousCache}