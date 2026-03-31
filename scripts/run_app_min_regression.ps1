$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appDir = Join-Path $scriptDir '..\app'

Push-Location $appDir
try {
  flutter test test/unit/util/discovery_filter_test.dart
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  flutter test test/unit/provider/nearby_devices_provider_test.dart
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}
finally {
  Pop-Location
}