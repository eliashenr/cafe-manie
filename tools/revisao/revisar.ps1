param([string]$Variant = 'mostruario', [string]$Time = 'dia')
# Abre o jogo para a revisao do PO: uma janela so, minimizada na barra de tarefas, com dados isolados (nada e salvo).
# Uso: powershell -File tools\revisao\revisar.ps1 -Variant mostruario
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$work = "$root\build\revisao"
New-Item -ItemType Directory -Force "$work\appdata" | Out-Null
$env:APPDATA = "$work\appdata"
Start-Process 'C:\Godot\Godot_v4.7.2-stable_win64.exe' -WindowStyle Minimized -ArgumentList @('--path', $root, '--resolution', '1280x720', '-s', 'res://tools/art_sample.gd', '--', 'revisao.png', $Variant, $Time, 'revisao')
