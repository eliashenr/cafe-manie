param([ValidateSet('dia','noite')][string]$Time = 'dia')
$ErrorActionPreference = 'Stop'
$scenarioProject = (Resolve-Path "$PSScriptRoot\..\..").Path
$scenarioData = Join-Path $scenarioProject 'build\visual-cenario\interactive'
$scenarioGodot = 'C:\Godot\Godot_v4.7.2-stable_win64.exe'
New-Item -ItemType Directory -Force -Path "$scenarioData\appdata", "$scenarioData\localappdata" | Out-Null
$previousScenarioAppData = $env:APPDATA
$previousScenarioLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = "$scenarioData\appdata"
    $env:LOCALAPPDATA = "$scenarioData\localappdata"
    $scenarioArgs = @('--path', "`"$scenarioProject`"", '--resolution', '1280x720', '-s',
        'res://tools/revisao/cenario_codex.gd', '--', 'revisao.png', 'mostruario', $Time, 'revisao')
    $scenarioProcess = Start-Process -FilePath $scenarioGodot -WindowStyle Minimized -ArgumentList $scenarioArgs -PassThru
    Write-Output "Revisão do Cenário aberta minimizada (processo $($scenarioProcess.Id)). C: coleções completas; N: dia/noite. Sem salvar."
}
finally {
    $env:APPDATA = $previousScenarioAppData
    $env:LOCALAPPDATA = $previousScenarioLocalAppData
}
