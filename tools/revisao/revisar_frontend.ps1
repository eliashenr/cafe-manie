param(
    [ValidateSet('revisao','foto')][string]$Mode = 'revisao',
    [ValidateSet('cafe','suite')][string]$View = 'cafe',
    [ValidateSet('1280x720','960x540')][string]$Resolution = '1280x720',
    [ValidateSet('dia','noite')][string]$Time = 'dia',
    [string]$Out = ''
)
# DT-111. Revisão interativa fora da sandbox, minimizada; fotos ocultas.
# A cena injeta a simulação em memória e desativa a persistência do som.
$ErrorActionPreference = 'Stop'
$reviewProject = (Resolve-Path "$PSScriptRoot\..\..").Path
$reviewBase = Join-Path $reviewProject 'build\frontend'
$reviewGodot = if ($Mode -eq 'foto') { 'C:\Godot\Godot_v4.7.2-stable_win64_console.exe' } else { 'C:\Godot\Godot_v4.7.2-stable_win64.exe' }
if (-not (Test-Path -LiteralPath $reviewGodot)) { throw "Godot não encontrada: $reviewGodot" }
$reviewData = Join-Path $reviewBase $(if ($Mode -eq 'foto') { "capture-$Resolution" } else { 'interactive' })
New-Item -ItemType Directory -Force -Path "$reviewData\appdata", "$reviewData\localappdata" | Out-Null
if (-not $Out) { $Out = Join-Path $reviewBase "capturas\frontend_$Resolution.png" }
$Out = [IO.Path]::GetFullPath($Out)
if ($Mode -eq 'foto') { New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Out) | Out-Null }
$previousReviewAppData = $env:APPDATA
$previousReviewLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = "$reviewData\appdata"
    $env:LOCALAPPDATA = "$reviewData\localappdata"
    $reviewArgs = @('--path', "`"$reviewProject`"", '--resolution', $Resolution, '-s',
        'res://tools/revisao/frontend_codex.gd', '--', "`"$Out`"", 'mostruario', $Time, $Mode, $View)
    if ($Mode -eq 'foto') {
        $reviewLog = [IO.Path]::ChangeExtension($Out, '.log')
        $reviewErr = [IO.Path]::ChangeExtension($Out, '.err')
        $reviewProcess = Start-Process -FilePath $reviewGodot -WindowStyle Hidden -Wait -PassThru -ArgumentList $reviewArgs -RedirectStandardOutput $reviewLog -RedirectStandardError $reviewErr
        if ($reviewProcess.ExitCode -ne 0) { throw "A captura falhou ($($reviewProcess.ExitCode)). Consulte $reviewLog e $reviewErr." }
        if (-not (Test-Path -LiteralPath $Out)) { throw "A captura não gerou a foto: $Out" }
        if (-not (Select-String -LiteralPath $reviewLog -SimpleMatch 'FRONTEND OK:' -Quiet)) { throw "Captura incompleta. Consulte $reviewLog e $reviewErr." }
        if ((Test-Path -LiteralPath $reviewErr) -and (Select-String -LiteralPath $reviewErr -Pattern 'ERROR|SCRIPT ERROR' -Quiet)) { throw "A captura registrou erro. Consulte $reviewErr." }
        Write-Output "Interface capturada: $Out. Log: $reviewLog"
    }
    else {
        $reviewProcess = Start-Process -FilePath $reviewGodot -WindowStyle Minimized -PassThru -ArgumentList $reviewArgs
        Write-Output "Revisão completa iniciada minimizada (processo $($reviewProcess.Id)). Loja, configurações e Cidade pelos botões do jogo. N: dia/noite. Sem salvar."
    }
}
finally {
    $env:APPDATA = $previousReviewAppData
    $env:LOCALAPPDATA = $previousReviewLocalAppData
}
