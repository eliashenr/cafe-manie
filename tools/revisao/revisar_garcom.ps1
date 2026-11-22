# Revisão interativa, iniciada pelo PO: apenas a simulação de amostra, sem save.
# O garçom usa a navegação e a velocidade do jogo. Para a janela aparecer na
# área de trabalho do PO, o agente deve executar este iniciador fora do sandbox;
# o duplo clique em Revisar Garcom.cmd já ocorre na sessão do próprio usuário.
$ErrorActionPreference = 'Stop'
$reviewProject = (Resolve-Path "$PSScriptRoot\..\..").Path
$reviewData = Join-Path $reviewProject 'build\visual-garcom'
New-Item -ItemType Directory -Force -Path "$reviewData\appdata", "$reviewData\localappdata" | Out-Null
$env:APPDATA = "$reviewData\appdata"
$env:LOCALAPPDATA = "$reviewData\localappdata"
$godotReview = 'C:\Godot\Godot_v4.7.2-stable_win64.exe'
if (-not (Test-Path -LiteralPath $godotReview)) { throw 'Godot não encontrada em C:\Godot.' }
$reviewArgs = @('--path', "`"$reviewProject`"", '--resolution', '1280x720',
    '-s', 'res://tools/revisao/garcom_codex.gd', '--', 'revisao.png', 'mostruario', 'dia', 'revisao')
Start-Process -FilePath $godotReview -WindowStyle Minimized -ArgumentList $reviewArgs
