<#
.SYNOPSIS
  Convert any image to a 600x800 grayscale GIF for a Kindle screensaver.
.DESCRIPTION
  Used by install.sh on Windows when ImageMagick is not available. Preserves
  aspect ratio, centers on a white 600x800 canvas, and saves as GIF.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\png2kindlegif.ps1 -In photo.png -Out screensaver.gif
#>
param(
    [Parameter(Mandatory = $true)][string]$In,
    [Parameter(Mandatory = $true)][string]$Out
)

Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Image]::FromFile((Resolve-Path $In).Path)
try {
    $bmp = New-Object System.Drawing.Bitmap 600, 800
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::White)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $ratio = [Math]::Min(600 / $src.Width, 800 / $src.Height)
    $w = [int]($src.Width * $ratio)
    $h = [int]($src.Height * $ratio)
    $x = [int]((600 - $w) / 2)
    $y = [int]((800 - $h) / 2)
    $g.DrawImage($src, $x, $y, $w, $h)
    $g.Dispose()
    $bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Gif)
    $bmp.Dispose()
    Write-Host "Wrote $Out (600x800 GIF)"
}
finally {
    $src.Dispose()
}
