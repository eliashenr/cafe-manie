param(
    [ValidateSet('revisao','foto')][string]$Mode = 'revisao',
    [ValidateSet('tamanho','detalhe','suite','movimento')][string]$View = 'tamanho',
    [ValidateSet('1280x720','960x540')][string]$Resolution = '1280x720',
    [ValidateSet('dia','noite')][string]$Time = 'dia',
    [switch]$Detail,
    [string]$Out = ''
)
# Chef aprovado, movimento discreto e olhos locais. Sem alterar o avatar/save de produção.
# Revisão interativa: executar FORA da sandbox no desktop do PO, sempre minimizada.
# Fotos: janela oculta, dados isolados e sequência determinística. Não importa recursos.
$ErrorActionPreference = 'Stop'
$chefProject = (Resolve-Path "$PSScriptRoot\..\..").Path
$chefBase = Join-Path $chefProject 'build\chef-animado'
$chefAsset = Join-Path $chefProject 'art\avatar\chef_vestido_v1.png'
if (-not (Test-Path -LiteralPath $chefAsset)) { throw "A imagem aprovada não foi encontrada: $chefAsset" }
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
    $chefSize = if ($Detail -or $View -eq 'detalhe') { 'detalhe' } else { 'tamanho' }
    $chefArgs = @('--path', "`"$chefProject`"", '--resolution', $Resolution, '-s',
        'res://tools/revisao/chef_animado_codex.gd', '--', "`"$Out`"", 'mostruario', $Time, $Mode, $chefSize, $View)
    if ($Mode -eq 'foto') {
        $chefLog = [IO.Path]::ChangeExtension($Out, '.log')
        $chefErr = [IO.Path]::ChangeExtension($Out, '.err')
        $chefProcess = Start-Process -FilePath $chefGodot -WindowStyle Hidden -Wait -PassThru -ArgumentList $chefArgs -RedirectStandardOutput $chefLog -RedirectStandardError $chefErr
        if ($chefProcess.ExitCode -ne 0) { throw "A captura falhou ($($chefProcess.ExitCode)). Consulte $chefLog e $chefErr." }
        if (-not (Test-Path -LiteralPath $Out)) { throw "A captura não gerou a foto: $Out" }
        if (-not (Select-String -LiteralPath $chefLog -SimpleMatch 'CHEF ANIMADO OK:' -Quiet)) { throw "A captura não confirmou a conclusão. Consulte $chefLog e $chefErr." }
        Write-Output "Chef animado capturado: $Out. Modo: $View. Log: $chefLog"
    }
    else {
        $chefProcess = Start-Process -FilePath $chefGodot -WindowStyle Minimized -PassThru -ArgumentList $chefArgs
        Write-Output "Chef animado iniciado minimizado (processo $($chefProcess.Id)). Espaço: pausa; G: cumprimento; D: detalhe; C: chef. Sem salvar."
    }
}
finally {
    $env:APPDATA = $previousChefAppData
    $env:LOCALAPPDATA = $previousChefLocalAppData
}
