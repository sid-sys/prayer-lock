# Cuts the app icon, logo and the praying girl out of the branding sheet
# ("Prayer Lock App Branding Showcase.png", 1536 x 1024) into the app's asset files.
# The sheet is small, so the results are soft. Replace the files with the
# original high resolution art when you have it, and run `dart run flutter_launcher_icons`.
#
# Run:  powershell -File tools\make_brand_assets.ps1

param([string]$SheetPath = (Join-Path $env:USERPROFILE 'Downloads\Prayer Lock App Branding Showcase.png'))

Add-Type -AssemblyName System.Drawing
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$sheet = [System.Drawing.Bitmap]::FromFile($SheetPath)

function New-Canvas([int]$w, [int]$h) {
  $b = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  return $b
}
function Set-Quality($g) {
  $g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'
  $g.PixelOffsetMode = 'HighQuality'; $g.CompositingQuality = 'HighQuality'
}
function Get-RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r * 2
  $p.AddArc($x, $y, $d, $d, 180, 90); $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90); $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $p.CloseFigure(); return $p
}

# ---- app icon: the squircle on the sheet is x 45..370, y 176..509 ----
$src = New-Object System.Drawing.Rectangle(82, 218, 251, 251)   # inside the baked rounded corners, so no outline shows
$orange = $sheet.GetPixel(75, 215)                               # sampled from inside the icon
# full-bleed 1024 icon: orange field + the art clipped to a rounded square
$icon = New-Canvas 1024 1024
$g = [System.Drawing.Graphics]::FromImage($icon); Set-Quality $g
$g.Clear($orange)
# full square: iPhone and Android round the corners themselves

$g.DrawImage($sheet, (New-Object System.Drawing.Rectangle(0, 0, 1024, 1024)), $src.X, $src.Y, $src.Width, $src.Height, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$icon.Save((Join-Path $root 'assets\icon\icon.png'), [System.Drawing.Imaging.ImageFormat]::Png)

# ---- logo (rounded square with transparent corners, used inside the app) ----
$logo = New-Canvas 512 512
$g = [System.Drawing.Graphics]::FromImage($logo); Set-Quality $g
$g.Clear([System.Drawing.Color]::Transparent)
$g.SetClip((Get-RoundedPath 0 0 512 512 118))
$g.DrawImage($sheet, (New-Object System.Drawing.Rectangle(0, 0, 512, 512)), 45, 176, 325, 333, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$logo.Save((Join-Path $root 'assets\img\logo.png'), [System.Drawing.Imaging.ImageFormat]::Png)

# ---- praying girl frames: the background is key-coloured away ----
function Cut-Frame([int]$cx, [int]$y0, [int]$halfW, [int]$h, [string]$name) {
  $x0 = $cx - $halfW
  $bg = $sheet.GetPixel($x0 + 2, $y0 + $h - 2)
  $w = $halfW * 2
  $ow = $w * 2; $oh = $h * 2
  $out = New-Canvas $ow $oh
  $tmp = New-Canvas $ow $oh
  $g = [System.Drawing.Graphics]::FromImage($tmp); Set-Quality $g
  $g.DrawImage($sheet, (New-Object System.Drawing.Rectangle(0, 0, $ow, $oh)), $x0, $y0, $w, $h, [System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose()
  for ($yy = 0; $yy -lt $tmp.Height; $yy++) {
    for ($xx = 0; $xx -lt $tmp.Width; $xx++) {
      $c = $tmp.GetPixel($xx, $yy)
      $d = [math]::Sqrt([math]::Pow($c.R - $bg.R, 2) + [math]::Pow($c.G - $bg.G, 2) + [math]::Pow($c.B - $bg.B, 2))
      $a = [math]::Min(1.0, [math]::Max(0.0, ($d - 14) / 26))
      $out.SetPixel($xx, $yy, [System.Drawing.Color]::FromArgb([int](255 * $a), $c.R, $c.G, $c.B))
    }
  }
  $out.Save((Join-Path $root "assets\img\$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
  $out.Dispose(); $tmp.Dispose()
}
$centers = @(82, 175, 268, 370, 465)
for ($i = 0; $i -lt 5; $i++) { Cut-Frame $centers[$i] 812 47 116 ("girl_pray_" + ($i + 1)) }

# ---- colours for the splash and the launch screen ----
$top = $sheet.GetPixel(440, 60)
$bot = $sheet.GetPixel(440, 690)
Write-Host ("splash top  #{0:X2}{1:X2}{2:X2}" -f $top.R, $top.G, $top.B)
Write-Host ("splash bottom #{0:X2}{1:X2}{2:X2}" -f $bot.R, $bot.G, $bot.B)
Write-Host ("icon orange #{0:X2}{1:X2}{2:X2}" -f $orange.R, $orange.G, $orange.B)
# ---- splash and sign up art: exact crops of the sheet (status bar and phone frame left out) ----
function Save-Crop([int]$x, [int]$y, [int]$w, [int]$h, [int]$scale, [string]$name) {
  $b = New-Canvas ($w * $scale) ($h * $scale)
  $gg = [System.Drawing.Graphics]::FromImage($b); Set-Quality $gg
  $gg.DrawImage($sheet, (New-Object System.Drawing.Rectangle(0, 0, ($w * $scale), ($h * $scale))), $x, $y, $w, $h, [System.Drawing.GraphicsUnit]::Pixel)
  $gg.Dispose()
  $b.Save((Join-Path $root "assetsimg$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
  $b.Save((Join-Path $root ('assets\img\' + $name + '.png')), [System.Drawing.Imaging.ImageFormat]::Png)
}
Save-Crop 412 58 318 640 3 splash_art
Save-Crop 802 96 228 174 4 login_top
Write-Host ('login cream #{0:X2}{1:X2}{2:X2}' -f $sheet.GetPixel(815,100).R, $sheet.GetPixel(815,100).G, $sheet.GetPixel(815,100).B)
Save-Crop 770 486 292 214 3 login_bottom
$sheet.Dispose()



