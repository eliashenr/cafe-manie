# Revisão interativa iniciada pelo PO; simulação em memória, com dados locais isolados.
# Executar no desktop do usuário, fora da sandbox: uma janela na estação isolada não aparece na barra de tarefas.
$ErrorActionPreference = 'Stop'
$reviewProject = (Resolve-Path "$PSScriptRoot\..\..").Path
$reviewData = Join-Path $reviewProject 'build\visual-clientes'
$godotReview = 'C:\Godot\Godot_v4.7.2-stable_win64.exe'
if (-not (Test-Path -LiteralPath $godotReview)) { throw 'Godot não encontrada em C:\Godot.' }
New-Item -ItemType Directory -Force -Path "$reviewData\appdata", "$reviewData\localappdata" | Out-Null
$previousReviewAppData = $env:APPDATA
$previousReviewLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = "$reviewData\appdata"
    $env:LOCALAPPDATA = "$reviewData\localappdata"
    $reviewArgs = @('--path', "`"$reviewProject`"", '--resolution', '1280x720',
        '-s', 'res://tools/revisao/clientes_codex.gd', '--', 'revisao.png', 'mostruario', 'dia', 'revisao')
    $reviewProcess = Start-Process -FilePath $godotReview -WindowStyle Minimized -ArgumentList $reviewArgs -PassThru
    Write-Output "Revisão dos clientes iniciada (processo $($reviewProcess.Id)). N: dia/noite; 1/2: lotes; 0: todos."
}
finally {
    $env:APPDATA = $previousReviewAppData
    $env:LOCALAPPDATA = $previousReviewLocalAppData
}
