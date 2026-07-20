# 단위 테스트 실행 헬퍼.
# dotnet build 후 tests/tests.tscn 을 헤드리스로 돌려 결과를 콘솔에 출력하고,
# 실패 개수를 종료 코드로 반환한다.
#
# 사용:  ./run_tests.ps1

$ErrorActionPreference = "Stop"
$projectDir = $PSScriptRoot

# Godot .NET 실행 파일: PATH에 있으면 그걸, 없으면 tools 폴더의 콘솔 빌드.
$godot = (Get-Command godot -ErrorAction SilentlyContinue).Source
if (-not $godot) {
	$godot = Join-Path $projectDir "..\tools\Godot_v4.7.1-stable_mono_win64\Godot_v4.7.1-stable_mono_win64_console.exe"
}
if (-not (Test-Path $godot)) {
	Write-Error "Godot .NET 실행 파일을 찾지 못했습니다: $godot`nrun_tests.ps1 의 `$godot 경로를 실제 설치 위치로 수정하세요."
	exit 2
}

# C# 빌드 먼저. 실패하면 테스트를 돌릴 수 없다.
Push-Location $projectDir
dotnet build --nologo -v q
$buildExit = $LASTEXITCODE
Pop-Location
if ($buildExit -ne 0) {
	Write-Error "dotnet build 실패 (exit $buildExit)"
	exit 2
}

$outFile = Join-Path $env:TEMP "godot_tests_out.txt"
$errFile = Join-Path $env:TEMP "godot_tests_err.txt"

$proc = Start-Process -FilePath $godot `
	-ArgumentList '--headless', '--path', '.', 'res://tests/tests.tscn' `
	-WorkingDirectory $projectDir -NoNewWindow -Wait -PassThru `
	-RedirectStandardOutput $outFile -RedirectStandardError $errFile

Get-Content $outFile
Get-Content $errFile

exit $proc.ExitCode
