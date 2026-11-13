param([string]$Script, [string]$Out, [string]$Variant, [string]$Time = 'dia', [string]$Mode = '', [string]$Extra = '')
# Foto do jogo sem aparecer na tela do PO: janela oculta e dados isolados (o save pessoal nunca e tocado).
# Uso: powershell -File tools\revisao\foto.ps1 -Script res://tools/revisao/superficies.gd -Out C:\...\s0.png -Variant surf:0 -Time dia -Mode fixa
$root = (Resolve-Path "$PSScriptRoot\..\..").Path
$work = "$root\build\revisao"
New-Item -ItemType Directory -Force "$work\appdata" | Out-Null
$env:APPDATA = "$work\appdata"
$godot = 'C:\Godot\Godot_v4.7.2-stable_win64_console.exe'
$a = @('--path', $root, '--resolution', '1280x720', '-s', $Script, '--', $Out, "`"$Variant`"", $Time)
if ($Mode) { $a += $Mode }
if ($Extra) { $a += $Extra }
Start-Process $godot -WindowStyle Hidden -Wait -RedirectStandardOutput "$work\foto.log" -RedirectStandardError "$work\foto.err" -ArgumentList $a
Select-String -Path "$work\foto.log", "$work\foto.err" -Pattern 'ERROR|coube|sem lugar' | ForEach-Object { $_.Line }
