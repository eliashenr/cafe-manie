param([string]$Variant = 'mostruario', [string]$Time = 'dia', [string]$Date = '')
# Abre o jogo para a revisao do PO: uma janela so, minimizada na barra de tarefas, com dados isolados (nada e salvo).
# Uso: & 'C:\Projetos\cafe-manie\tools\revisao\revisar.ps1' -Variant mostruario
#      -Date 2026-12-10 abre o jogo nesse dia (para revisar um evento, que so aparece nas datas dele).
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$work = "$root\build\revisao"
New-Item -ItemType Directory -Force "$work\appdata" | Out-Null
$env:APPDATA = "$work\appdata"
$a = @('--path', $root, '--resolution', '1280x720', '-s', 'res://tools/art_sample.gd', '--', 'revisao.png', $Variant, $Time, 'revisao')
if ($Date) { $a += $Date }
Start-Process 'C:\Godot\Godot_v4.7.2-stable_win64.exe' -WindowStyle Minimized -ArgumentList $a
