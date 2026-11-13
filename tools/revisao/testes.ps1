# Roda tudo o que a regra "nunca declare pronto" pede, sem janela e sem tocar no save pessoal:
# importa, roda os testes e sobe a cena principal por 120 quadros.
# Uso: powershell -File tools\revisao\testes.ps1
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$work = "$root\build\revisao"
New-Item -ItemType Directory -Force "$work\appdata" | Out-Null
$env:APPDATA = "$work\appdata"
$godot = 'C:\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --import --path $root *> $null
$tests = & $godot --headless --path $root -s res://tests/run_tests.gd 2>&1 | Out-String
$testsExit = $LASTEXITCODE
($tests -split "`n" | Where-Object { $_ -match 'FALHOU|passaram|ERROR' } | Select-Object -Last 40) -join "`n"
"testes exit=$testsExit"
$scene = & $godot --headless --path $root --quit-after 120 2>&1 | Out-String
$sceneExit = $LASTEXITCODE
($scene -split "`n" | Where-Object { $_ -match 'ERROR|SCRIPT' } | Select-Object -First 20) -join "`n"
"cena exit=$sceneExit"
$save = "$([Environment]::GetFolderPath('ApplicationData'))\Godot\app_userdata\Café Manie\save.json"
if (Test-Path $save) { "save pessoal: $((Get-Item $save).LastWriteTime)" }
