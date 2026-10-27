# Makes the Google Play graphics from the brand sheet:
#   store\play\feature_graphic_1024x500.png   (featured image)
#   store\play\app_icon_512.png               (app icon for the store listing)
# Run:  powershell -File tools\make_play_graphics.ps1

param([string]$SheetPath = (Join-Path $env:USERPROFILE 'Downloads\Prayer Lock App Branding Showcase.png'))
Add-Type -AssemblyName System.Drawing
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$out = Join-Path $root 'store\play'
$sheet = [System.Drawing.Bitmap]::FromFile($SheetPath)

# ---- app icon 512 ----
$icon = [System.Drawing.Image]::FromFile((Join-Path $root 'assets\icon\icon.png'))
$i512 = New-Object System.Drawing.Bitmap 512, 512
$g = [System.Drawing.Graphics]::FromImage($i512)
$g.InterpolationMode = 'HighQualityBicubic'; $g.SmoothingMode = 'AntiAlias'; $g.PixelOffsetMode = 'HighQuality'
$g.DrawImage($icon, 0, 0, 512, 512); $g.Dispose()
$i512.Save((Join-Path $out 'app_icon_512.png'), [System.Drawing.Imaging.ImageFormat]::Png)

# ---- feature graphic 1024 x 500 ----
$W = 1024; $H = 500
$b = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($b)
$g.InterpolationMode = 'HighQualityBicubic'; $g.SmoothingMode = 'AntiAlias'
$g.TextRenderingHint = 'AntiAliasGridFit'; $g.PixelOffsetMode = 'HighQuality'

# the featured picture on the sheet (girl praying over the Bible, sunset valley) fills the right side
$artW = 418
$g.DrawImage($sheet, (New-Object System.Drawing.Rectangle(($W - $artW), 0, $artW, $H)), 1096, 158, 424, 506, [System.Drawing.GraphicsUnit]::Pixel)

# left side: warm gradient that melts into the picture
$left = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  (New-Object System.Drawing.Point(0, 0)), (New-Object System.Drawing.Point(($W - $artW + 40), 0)),
  [System.Drawing.Color]::FromArgb(255, 255, 150, 80), [System.Drawing.Color]::FromArgb(255, 255, 196, 140))
$g.FillRectangle($left, 0, 0, ($W - $artW), $H)
$fade = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  (New-Object System.Drawing.Point(($W - $artW - 70), 0)), (New-Object System.Drawing.Point(($W - $artW + 20), 0)),
  [System.Drawing.Color]::FromArgb(255, 255, 196, 140), [System.Drawing.Color]::FromArgb(0, 255, 196, 140))
$g.FillRectangle($fade, ($W - $artW - 70), 0, 90, $H)

# logo (the app icon) and text
$g.DrawImage($icon, 46, 56, 150, 150)
$f1 = New-Object System.Drawing.Font('Arial Rounded MT Bold', 66, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$f2 = New-Object System.Drawing.Font('Segoe UI Semibold', 31, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$ink = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 30, 24, 34))
$g.DrawString('Prayer Lock', $f1, $ink, 40, 228)
$g.DrawString("Lock distracting apps.", $f2, $ink, 46, 316)
$g.DrawString("Pray first. Then scroll.", $f2, $ink, 46, 358)
$b.Save((Join-Path $out 'feature_graphic_1024x500.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $b.Dispose(); $icon.Dispose(); $i512.Dispose(); $sheet.Dispose()
Write-Host 'saved feature_graphic_1024x500.png and app_icon_512.png'

