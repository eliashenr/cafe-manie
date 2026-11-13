param([string]$Out, [string]$Suffix, [string[]]$Ids, [int]$Cols = 6, [int]$Cell = 250)
Add-Type -AssemblyName System.Drawing
$sprites = (Resolve-Path "$PSScriptRoot\..\..\art\sprites").Path
$rows = [Math]::Ceiling($Ids.Count / $Cols)
$bmp = New-Object System.Drawing.Bitmap ($Cols * $Cell), ($rows * $Cell)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::FromArgb(150, 110, 75))
$g.InterpolationMode = 'HighQualityBicubic'
$font = New-Object System.Drawing.Font 'Arial', 11
for ($i = 0; $i -lt $Ids.Count; $i++) {
    $x = ($i % $Cols) * $Cell
    $y = [Math]::Floor($i / $Cols) * $Cell
    $file = Join-Path $sprites ($Ids[$i] + $Suffix + '.png')
    if (Test-Path $file) {
        $im = [System.Drawing.Image]::FromFile($file)
        $scale = [Math]::Min(($Cell - 24) / $im.Width, ($Cell - 24) / $im.Height)
        $w = [int]($im.Width * $scale); $h = [int]($im.Height * $scale)
        $g.DrawImage($im, ($x + ($Cell - $w) / 2), ($y + 20), $w, $h)
        $im.Dispose()
    }
    $g.DrawString($Ids[$i], $font, [System.Drawing.Brushes]::White, $x + 3, $y + 2)
}
$bmp.Save($Out); $g.Dispose(); $bmp.Dispose()
