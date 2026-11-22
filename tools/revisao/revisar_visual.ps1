param(
    [ValidateSet('dia','noite')][string]$Time = 'dia',
    [ValidateSet('','japao','brasil','italia','franca','mexico','japones','brasileiro','italiano','frances','mexicano','americano','country','festa','anos70','anos80','anos2010','balada')][string]$Collection = ''
)
# Revisão interativa autorizada pelo PO: café real em memória, sem ler/gravar o save pessoal.
# Executar no desktop do usuário, fora da sandbox: a estação isolada não aparece na barra de tarefas.
# A janela nasce minimizada. O PO pode restaurá-la quando desejar; não trazer para a frente.
$ErrorActionPreference = 'Stop'
$reviewProject = (Resolve-Path "$PSScriptRoot\..\..").Path
$reviewData = Join-Path $reviewProject 'build\visual-reformulacao\interactive'
$godotReview = 'C:\Godot\Godot_v4.7.2-stable_win64.exe'
if (-not (Test-Path -LiteralPath $godotReview)) { throw 'Godot não encontrada em C:\Godot.' }
New-Item -ItemType Directory -Force -Path "$reviewData\appdata", "$reviewData\localappdata" | Out-Null
$previousReviewAppData = $env:APPDATA
$previousReviewLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = "$reviewData\appdata"
    $env:LOCALAPPDATA = "$reviewData\localappdata"
    $reviewArgs = @('--path', "`"$reviewProject`"", '--resolution', '1280x720',
        '-s', 'res://tools/revisao/visual_codex.gd', '--', 'revisao.png', 'mostruario', $Time, 'revisao')
    if ($Collection) { $reviewArgs += "colecao:$Collection" }
    $reviewProcess = Start-Process -FilePath $godotReview -WindowStyle Minimized -ArgumentList $reviewArgs -PassThru
    Write-Output "Revisão Visual iniciada minimizada (processo $($reviewProcess.Id)). C: coleções; N: dia/noite; 1/2: lotes; 0: todos. Sem salvar."
}
finally {
    $env:APPDATA = $previousReviewAppData
    $env:LOCALAPPDATA = $previousReviewLocalAppData
}
