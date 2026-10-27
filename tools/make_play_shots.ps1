# Makes the Google Play phone screenshots: 1080 x 1920 PNG (9:16).
# Orange background, a caption, and a real app screenshot inside a phone frame.
# Run:  powershell -File tools\make_play_shots.ps1
# Input: PNG screenshots taken on a phone (720 x 1612). Output: store\play\01_*.png ...

Add-Type -AssemblyName System.Drawing

$inDir  = Join-Path $env:TEMP 's'          # where the phone screenshots were saved
$outDir = Join-Path $PSScriptRoot '..\store\play'
New-Item -ItemType Directory -Force $outDir | Out-Null

# file (in $inDir), caption, small text
$shots = @(
  @('s1_intro.png',      'Pray before you scroll',       'Locked apps ask for a short prayer first'),
  @('s2_mood_b.png',     'A daily check-in with God',    'Share how close you feel today'),
  @('s4_prayer_final2.png',     'A prayer for your strength',     'Plus the verse of the day, every time'),
  @('h0.png',            'Build a daily prayer streak',  'Morning, night and every pause counts'),
  @('s7_compare.png',    'Your time, with and without',  'See your year with Prayer Lock'),
  @('s8c.png',           'Take your time back',          'See how many minutes stayed yours'),
  @('s8b.png',           'Know your locked apps',        'How often each app paused you, and for how long'),
  @('f8.png',            'Understand your heart',        'Your feelings and closeness over time')
)

function Get-RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r * 2
  $p.AddArc($x, $y, $d, $d, 180, 90)
  $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
  $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
  $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
  $p.CloseFigure()
  return $p
}

function Draw-Centered($g, [string]$text, $font, $brush, [float]$cx, [float]$y, [float]$maxW) {
  $fmt = New-Object System.Drawing.StringFormat
  $fmt.Alignment = [System.Drawing.StringAlignment]::Center
  $rect = New-Object System.Drawing.RectangleF(($cx - $maxW / 2), $y, $maxW, 400)
  $g.DrawString($text, $font, $brush, $rect, $fmt)
}

$W = 1080; $H = 1920
$i = 0
foreach ($s in $shots) {
  $i++
  $src = Join-Path $inDir $s[0]
  if (-not (Test-Path $src)) { Write-Host "missing $src"; continue }
  $shot = [System.Drawing.Image]::FromFile($src)

  $bmp = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'
  $g.InterpolationMode = 'HighQualityBicubic'
  $g.TextRenderingHint = 'AntiAliasGridFit'
  $g.PixelOffsetMode = 'HighQuality'

  # background: warm orange gradient
  $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.Point(0, 0)), (New-Object System.Drawing.Point(0, $H)),
    [System.Drawing.Color]::FromArgb(255, 255, 122, 41), [System.Drawing.Color]::FromArgb(255, 255, 170, 90))
  $g.FillRectangle($bg, 0, 0, $W, $H)

  # caption
  # shrink the headline until it fits on one line
  $size = 74
  do {
    $f1 = New-Object System.Drawing.Font('Arial Rounded MT Bold', $size, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $tw = $g.MeasureString($s[1], $f1).Width
    $size -= 2
  } while ($tw -gt 960 -and $size -gt 40)
  $f2 = New-Object System.Drawing.Font('Segoe UI Semibold', 40, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
  $white = [System.Drawing.Brushes]::White
  $soft = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(235, 255, 255, 255))
  Draw-Centered $g $s[1] $f1 $white ($W / 2) 86 960
  Draw-Centered $g $s[2] $f2 $soft ($W / 2) 196 940

  # phone: crop the app area (no status bar, no navigation bar)
  $cropY = 66; $cropH = 1466
  $phoneW = 820
  $scale = $phoneW / 720.0
  $screenH = [int]($cropH * $scale)
  $bezel = 20
  $px = ($W - $phoneW) / 2 - $bezel
  $py = 330
  $frameW = $phoneW + 2 * $bezel
  $frameH = $screenH + 2 * $bezel + 40   # runs past the bottom edge on purpose

  # soft shadow
  $shadow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70, 80, 30, 0))
  $sp = Get-RoundedPath ($px + 8) ($py + 16) $frameW $frameH 96
  $g.FillPath($shadow, $sp)

  $fp = Get-RoundedPath $px $py $frameW $frameH 96
  $g.FillPath((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 24, 24, 30))), $fp)

  $sx = $px + $bezel; $sy = $py + $bezel
  $clip = Get-RoundedPath $sx $sy $phoneW $screenH 76
  $g.SetClip($clip)
  $dest = New-Object System.Drawing.Rectangle([int]$sx, [int]$sy, $phoneW, $screenH)
  $g.DrawImage($shot, $dest, 0, $cropY, 720, $cropH, [System.Drawing.GraphicsUnit]::Pixel)
  $g.ResetClip()

  $name = '{0:D2}_{1}.png' -f $i, (($s[1].ToLower() -replace '[^a-z0-9]+', '_').Trim('_'))
  $bmp.Save((Join-Path $outDir $name), [System.Drawing.Imaging.ImageFormat]::Png)
  Write-Host "saved $name"
  $g.Dispose(); $bmp.Dispose(); $shot.Dispose()
}

