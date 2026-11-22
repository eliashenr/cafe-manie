param(
    [ValidateSet('revisao','foto')][string]$Mode = 'revisao',
    [ValidateSet('tamanho','detalhe','suite')][string]$View = 'tamanho',
    [ValidateSet('1280x720','960x540')][string]$Resolution = '1280x720',
    [ValidateSet('dia','noite')][string]$Time = 'dia',
    [string]$Out = ''
)
# Prova do chef completo: uma fonte estática, café real e simulação em memória, sem save pessoal.
# A revisão interativa deve ser executada no desktop do PO, FORA da sandbox: a estação isolada fica invisível.
# A janela interativa nasce minimizada; não restaurar nem trazer para a frente automaticamente.
# Fotos usam janela oculta. Nenhum modo importa recursos ou altera o código/arte.
$ErrorActionPreference = 'Stop'
$chefProject = (Resolve-Path "$PSScriptRoot\..\..").Path
$chefBase = Join-Path $chefProject 'build\chef-vestido'
$chefAsset = Join-Path $chefProject 'art\avatar\chef_vestido_v1.png'
if (-not (Test-Path -LiteralPath $chefAsset)) { throw "A imagem do chef ainda não está pronta: $chefAsset" }
$chefGodot = if ($Mode -eq 'foto') { 'C:\Godot\Godot_v4.7.2-stable_win64_console.exe' } else { 'C:\Godot\Godot_v4.7.2-stable_win64.exe' }
if (-not (Test-Path -LiteralPath $chefGodot)) { throw "Godot não encontrada: $chefGodot" }
$chefData = Join-Path $chefBase $(if ($Mode -eq 'foto') { 'capture' } else { 'interactive' })
New-Item -ItemType Directory -Force -Path "$chefData\appdata", "$chefData\localappdata" | Out-Null
if (-not $Out) { $Out = Join-Path $chefBase "capturas\chef_$($Resolution)_$($View).png" }
$Out = [IO.Path]::GetFullPath($Out)
if ($Mode -eq 'foto') { New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Out) | Out-Null }
$previousChefAppData = $env:APPDATA
$previousChefLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = "$chefData\appdata"
    $env:LOCALAPPDATA = "$chefData\localappdata"
    $chefArgs = @('--path', "`"$chefProject`"", '--resolution', $Resolution, '-s',
        'res://tools/revisao/chef_vestido_codex.gd', '--', "`"$Out`"", 'mostruario', $Time, $Mode, $View)
    if ($Mode -eq 'foto') {
        $chefLog = [IO.Path]::ChangeExtension($Out, '.log')
        $chefErr = [IO.Path]::ChangeExtension($Out, '.err')
        $chefProcess = Start-Process -FilePath $chefGodot -WindowStyle Hidden -Wait -PassThru -ArgumentList $chefArgs -RedirectStandardOutput $chefLog -RedirectStandardError $chefErr
        if ($chefProcess.ExitCode -ne 0) { throw "A captura falhou ($($chefProcess.ExitCode)). Consulte $chefLog e $chefErr." }
        if (-not (Test-Path -LiteralPath $Out)) { throw "A captura não gerou a foto: $Out" }
        if (-not (Select-String -LiteralPath $chefLog -SimpleMatch 'CHEF VESTIDO OK:' -Quiet)) { throw "A captura não confirmou a conclusão. Consulte $chefLog e $chefErr." }
        Write-Output "Prova estática capturada: $Out"
        if ($View -eq 'suite') {
            $chefDetailOut = Join-Path (Split-Path -Parent $Out) "$([IO.Path]::GetFileNameWithoutExtension($Out))_detalhe.png"
            if (-not (Test-Path -LiteralPath $chefDetailOut)) { throw "A captura não gerou o detalhe: $chefDetailOut" }
            Write-Output "Detalhe: $chefDetailOut"
        }
    }
    else {
        $chefProcess = Start-Process -FilePath $chefGodot -WindowStyle Minimized -PassThru -ArgumentList $chefArgs
        Write-Output "Chef vestido iniciado minimizado (processo $($chefProcess.Id)). C: chef; D: detalhe; N: dia/noite. Sem salvar."
    }
}
finally {
    $env:APPDATA = $previousChefAppData
    $env:LOCALAPPDATA = $previousChefLocalAppData
}
