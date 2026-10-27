# Makes the App Store iPhone screenshots: 1320 x 2868 PNG (iPhone 6.9 inch).
# Orange background, a caption, and a real iPhone simulator screenshot in a phone frame.
#
# 1. Run the GitHub workflow "iOS simulator screenshots" and download its artifact.
# 2. Unzip the pictures into store\ios  (names like lockintro.png, prayer.png, ...).
# 3. Run:  powershell -File tools\make_ios_shots.ps1
# Output: store\appstore\01_*.png ... (upload these in App Store Connect).

param(
  [string]$InDir  = (Join-Path $PSScriptRoot '..\store\ios'),
  [string]$OutDir = (Join-Path $PSScriptRoot '..\store\appstore')
)
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force $OutDir | Out-Null

# file (in $InDir), caption, small text
$shots = @(
  @('lockintro.png',   'Pray before you scroll',      'Locked apps ask for a short prayer first'),
  @('prayer.png',      'A prayer for your strength',  'Plus the verse of the day, every time'),
  @('home.png',        'Build a daily prayer streak', 'Morning, night and every pause counts'),
  @('compare.png',     'Your time, with and without', 'See your year with Prayer Lock'),
  @('insights_a.png',  'Take your time back',         'See how many minutes stayed yours'),
  @('insights_b.png',  'Know your locked apps',       'How often each app paused you, and for how long'),
  @('insights_c.png',  'Understand your heart',       'Your feelings and closeness over time'),
  @('badges.png',      'Earn badges for faithfulness','Celebrate every step with God')
)

function Get-RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r * 2
  $p.AddArc($x, $y, $d, $d, 180, 90); $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90); $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $p.CloseFigure(); return $p
}
function Draw-Centered($g, [string]$text, $font, $brush, [float]$cx, [float]$y, [float]$maxW) {
  $fmt = New-Object System.Drawing.StringFormat
  $fmt.Alignment = [System.Drawing.StringAlignment]::Center
  $g.DrawString($text, $font, $brush, (New-Object System.Drawing.RectangleF(($cx - $maxW / 2), $y, $maxW, 400)), $fmt)
}

$W = 1320; $H = 2868
$i = 0
foreach ($s in $shots) {
  $i++
  $src = Join-Path $InDir $s[0]
  if (-not (Test-Path $src)) { Write-Host "missing $src"; continue }
  $shot = [System.Drawing.Image]::FromFile($src)
  $bmp = New-Object System.Drawing.Bitmap $W, $H
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'
  $g.TextRenderingHint = 'AntiAliasGridFit'; $g.PixelOffsetMode = 'HighQuality'

  $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.Point(0, 0)), (New-Object System.Drawing.Point(0, $H)),
    [System.Drawing.Color]::FromArgb(255, 255, 122, 41), [System.Drawing.Color]::FromArgb(255, 255, 170, 90))
  $g.FillRectangle($bg, 0, 0, $W, $H)

  # headline: shrink until it fits on one line
  $size = 112
  do {
    $f1 = New-Object System.Drawing.Font('Arial Rounded MT Bold', $size, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $tw = $g.MeasureString($s[1], $f1).Width; $size -= 2
  } while ($tw -gt 1180 -and $size -gt 50)
  $f2 = New-Object System.Drawing.Font('Segoe UI Semibold', 56, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
  Draw-Centered $g $s[1] $f1 ([System.Drawing.Brushes]::White) ($W / 2) 120 1240
  Draw-Centered $g $s[2] $f2 (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(235, 255, 255, 255))) ($W / 2) 270 1200

  # phone frame with the whole simulator picture inside
  $bezel = 26
  $innerW = 1010
  $innerH = [int]($innerW * $shot.Height / $shot.Width)
  $px = ($W - $innerW) / 2 - $bezel
  $py = 420
  $frameW = $innerW + 2 * $bezel
  $frameH = $innerH + 2 * $bezel
  $g.FillPath((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70, 80, 30, 0))), (Get-RoundedPath ($px + 10) ($py + 20) $frameW $frameH 150))
  $g.FillPath((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 24, 24, 30))), (Get-RoundedPath $px $py $frameW $frameH 150))
  $sx = $px + $bezel; $sy = $py + $bezel
  $g.SetClip((Get-RoundedPath $sx $sy $innerW $innerH 124))
  $g.DrawImage($shot, (New-Object System.Drawing.Rectangle([int]$sx, [int]$sy, $innerW, $innerH)))
  $g.ResetClip()

  $name = '{0:D2}_{1}.png' -f $i, (($s[1].ToLower() -replace '[^a-z0-9]+', '_').Trim('_'))
  $bmp.Save((Join-Path $OutDir $name), [System.Drawing.Imaging.ImageFormat]::Png)
  Write-Host "saved $name ($W x $H)"
  $g.Dispose(); $bmp.Dispose(); $shot.Dispose()
}
