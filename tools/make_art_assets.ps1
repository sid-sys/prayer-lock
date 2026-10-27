# Cuts the ChatGPT sprite sheets in store\ into single PNG files in assets\img.
# White backgrounds become transparent (flood fill from the cell edge, so white
# parts INSIDE a picture stay). Edges are un-matted, so there is no white halo.
#
# Run:  powershell -File tools\make_art_assets.ps1
# Sheets (in store\):
#   Pastel Kawaii Icon Sticker Grid.png        10 x 5 small icons        -> ic_*.png
#   Glossy Golden Achievement Badge Grid.png   5 x 4 badges              -> badge_*.png, b_*.png
#   Kawaii Faith and Joy Sprite Sheet.png      6 x 3 girl animation      -> girl_pray_N, girl_read_N, girl_joy_N
#   Pastel Faith and Joy Sticker Grid.png      4 x 4 illustrations       -> il_*.png
#   Dreamy Pastel Celebration Panels.png       2 x 2 backgrounds         -> bg_*.png (no keying)

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;

public static class Slicer {
  // Crop [x0,x1) x [y0,y1) from src, remove white background, return the bitmap (32bpp ARGB).
  public static Bitmap CutCell(Bitmap src, int x0, int y0, int x1, int y1, bool key, int t1) {
    int w = x1 - x0, h = y1 - y0;
    Bitmap o = new Bitmap(w, h, PixelFormat.Format32bppArgb);
    Rectangle r = new Rectangle(0, 0, w, h);
    using (Bitmap crop = src.Clone(new Rectangle(x0, y0, w, h), PixelFormat.Format32bppArgb)) {
      BitmapData d = crop.LockBits(r, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
      int n = w * h; byte[] px = new byte[d.Stride * h];
      System.Runtime.InteropServices.Marshal.Copy(d.Scan0, px, 0, px.Length);
      crop.UnlockBits(d);
      int stride = d.Stride;
      byte[] outpx = new byte[px.Length];
      Array.Copy(px, outpx, px.Length);
      if (key) {
        // distance from white for every pixel
        int[] dist = new int[n];
        for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
          int i = y * stride + x * 4;
          int dd = Math.Max(255 - px[i], Math.Max(255 - px[i + 1], 255 - px[i + 2]));
          dist[y * w + x] = dd;
        }
        bool[] bg = new bool[n];
        Stack<int> st = new Stack<int>();
        for (int x = 0; x < w; x++) { Seed(dist, bg, st, x, 0, w, t1); Seed(dist, bg, st, x, h - 1, w, t1); }
        for (int y = 0; y < h; y++) { Seed(dist, bg, st, 0, y, w, t1); Seed(dist, bg, st, w - 1, y, w, t1); }
        while (st.Count > 0) {
          int p = st.Pop(); int px0 = p % w, py0 = p / w;
          if (px0 > 0) Seed(dist, bg, st, px0 - 1, py0, w, t1);
          if (px0 < w - 1) Seed(dist, bg, st, px0 + 1, py0, w, t1);
          if (py0 > 0) Seed(dist, bg, st, px0, py0 - 1, w, t1);
          if (py0 < h - 1) Seed(dist, bg, st, px0, py0 + 1, w, t1);
        }
        for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
          int p = y * w + x; int i = y * stride + x * 4;
          if (!bg[p]) { outpx[i + 3] = 255; continue; }
          double a = (dist[p] - 6.0) / (t1 - 6.0);
          if (a < 0) a = 0; if (a > 1) a = 1;
          if (a <= 0.30) { outpx[i] = 0; outpx[i + 1] = 0; outpx[i + 2] = 0; outpx[i + 3] = 0; continue; }
          // un-matte against white
          for (int c = 0; c < 3; c++) {
            double v = 255.0 - (255.0 - px[i + c]) / a;
            if (v < 0) v = 0; if (v > 255) v = 255;
            outpx[i + c] = (byte)v;
          }
          outpx[i + 3] = (byte)(a * 255);
        }
      } else {
        for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) outpx[y * stride + x * 4 + 3] = 255;
      }
      BitmapData od = o.LockBits(r, ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
      System.Runtime.InteropServices.Marshal.Copy(outpx, 0, od.Scan0, outpx.Length);
      o.UnlockBits(od);
    }
    return o;
  }
  static void Seed(int[] dist, bool[] bg, Stack<int> st, int x, int y, int w, int t1) {
    int p = y * w + x;
    if (bg[p] || dist[p] > t1) return;
    bg[p] = true; st.Push(p);
  }

  // Bounding box of pixels with alpha > 10.
  public static Rectangle Bounds(Bitmap b) {
    int minx = b.Width, miny = b.Height, maxx = -1, maxy = -1;
    Rectangle r = new Rectangle(0, 0, b.Width, b.Height);
    BitmapData d = b.LockBits(r, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    byte[] px = new byte[d.Stride * b.Height];
    System.Runtime.InteropServices.Marshal.Copy(d.Scan0, px, 0, px.Length);
    b.UnlockBits(d);
    for (int y = 0; y < b.Height; y++) for (int x = 0; x < b.Width; x++) {
      if (px[y * d.Stride + x * 4 + 3] > 10) {
        if (x < minx) minx = x; if (x > maxx) maxx = x; if (y < miny) miny = y; if (y > maxy) maxy = y;
      }
    }
    if (maxx < 0) return new Rectangle(0, 0, b.Width, b.Height);
    return new Rectangle(minx, miny, maxx - minx + 1, maxy - miny + 1);
  }

  // Remove small stray pieces (parts of the neighbour picture that reach into this cell).
  // Keeps every blob that is at least 18% of the biggest blob (blobs closer than 8 px count as one).
  public static void KeepMain(Bitmap b) {
    int w = b.Width, h = b.Height; Rectangle r = new Rectangle(0, 0, w, h);
    BitmapData d = b.LockBits(r, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
    byte[] px = new byte[d.Stride * h];
    System.Runtime.InteropServices.Marshal.Copy(d.Scan0, px, 0, px.Length);
    int s = d.Stride; int R = 8;
    bool[] on = new bool[w * h];
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) on[y * w + x] = px[y * s + x * 4 + 3] > 10;
    // dilate by R (box)
    bool[] dil = new bool[w * h];
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) if (on[y * w + x]) {
      int y0 = Math.Max(0, y - R), y1 = Math.Min(h - 1, y + R), x0 = Math.Max(0, x - R), x1 = Math.Min(w - 1, x + R);
      for (int yy = y0; yy <= y1; yy++) for (int xx = x0; xx <= x1; xx++) dil[yy * w + xx] = true;
    }
    int[] label = new int[w * h]; int n = 0; List<int> area = new List<int>();
    Stack<int> st = new Stack<int>();
    for (int p0 = 0; p0 < w * h; p0++) {
      if (!dil[p0] || label[p0] != 0) continue;
      n++; int a = 0; label[p0] = n; st.Push(p0);
      while (st.Count > 0) {
        int p = st.Pop(); int x = p % w, y = p / w; if (on[p]) a++;
        if (x > 0 && dil[p - 1] && label[p - 1] == 0) { label[p - 1] = n; st.Push(p - 1); }
        if (x < w - 1 && dil[p + 1] && label[p + 1] == 0) { label[p + 1] = n; st.Push(p + 1); }
        if (y > 0 && dil[p - w] && label[p - w] == 0) { label[p - w] = n; st.Push(p - w); }
        if (y < h - 1 && dil[p + w] && label[p + w] == 0) { label[p + w] = n; st.Push(p + w); }
      }
      area.Add(a);
    }
    int big = 0; foreach (int a in area) if (a > big) big = a;
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
      int l = label[y * w + x];
      if (l == 0 || area[l - 1] < big * 0.18) { int i = y * s + x * 4; px[i] = 0; px[i + 1] = 0; px[i + 2] = 0; px[i + 3] = 0; }
    }
    System.Runtime.InteropServices.Marshal.Copy(px, 0, d.Scan0, px.Length);
    b.UnlockBits(d);
  }

  // Trim to content, pad, optionally centre on a square canvas.
  public static Bitmap Finish(Bitmap b, int pad, bool square) {
    Rectangle bb = Bounds(b);
    int w = bb.Width + 2 * pad, h = bb.Height + 2 * pad;
    int cw = square ? Math.Max(w, h) : w, ch = square ? Math.Max(w, h) : h;
    Bitmap o = new Bitmap(cw, ch, PixelFormat.Format32bppArgb);
    using (Graphics g = Graphics.FromImage(o)) {
      g.Clear(Color.Transparent);
      g.DrawImage(b, new Rectangle((cw - bb.Width) / 2, (ch - bb.Height) / 2, bb.Width, bb.Height), bb, GraphicsUnit.Pixel);
    }
    return o;
  }
}
"@

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$store = Join-Path $root 'store'
$out = Join-Path $root 'assets\img'

function Even($start, $end, $n) { $a = @(); for ($i = 0; $i -le $n; $i++) { $a += [int]($start + ($end - $start) * $i / $n) }; return $a }

function Cut-Grid($sheetName, $xs, $ys, $names, [bool]$key, [int]$t1, [int]$inset, [bool]$trim, [bool]$square, [int]$pad, [bool]$clean = $false) {
  $bmp = [System.Drawing.Bitmap]::FromFile((Join-Path $store $sheetName))
  $k = 0
  for ($r = 0; $r -lt ($ys.Count - 1); $r++) {
    for ($c = 0; $c -lt ($xs.Count - 1); $c++) {
      $name = $names[$k]; $k++
      if (-not $name) { continue }
      $cell = [Slicer]::CutCell($bmp, $xs[$c] + $inset, $ys[$r] + $inset, $xs[$c + 1] - $inset, $ys[$r + 1] - $inset, $key, $t1)
      if ($clean) { [Slicer]::KeepMain($cell) }
      if ($trim) { $f = [Slicer]::Finish($cell, $pad, $square); $cell.Dispose(); $cell = $f }
      $cell.Save((Join-Path $out ($name + '.png')), [System.Drawing.Imaging.ImageFormat]::Png)
      $cell.Dispose()
    }
  }
  $bmp.Dispose()
  Write-Host "$sheetName : $k pictures"
}

# 1. icons: 10 x 5 (grid lines at x 16..1520, y 72..960)
$iconNames = @(
 'ic_home','ic_insights','ic_apps','ic_profile','ic_settings','ic_back','ic_close','ic_check','ic_plus','ic_share',
 'ic_home_on','ic_insights_on','ic_apps_on','ic_profile_on','ic_lock_cross','ic_unlock_cross','ic_shield','ic_pray','ic_bell','ic_bell_dot',
 'ic_flame','ic_sun','ic_moon','ic_dove','ic_fingerprint','ic_clock','ic_hourglass','ic_calendar','ic_chart_line','ic_donut',
 'ic_face_1','ic_face_2','ic_face_3','ic_face_4','ic_face_5','ic_trophy','ic_gift','ic_bell_ring','ic_lock_phone','ic_megaphone',
 'feel_grateful','feel_anxious','feel_tired','feel_hopeful','feel_sad','feel_stressed','feel_peaceful','feel_lost','ic_sun_smile','ic_rain_cloud')
Cut-Grid 'Pastel Kawaii Icon Sticker Grid.png' (Even 16 1520 10) @(72,247,428,607,783,960) $iconNames $true 44 10 $true $true 4

# 2. badges: 5 x 4 (columns 0..1214, rows split between the medal rows)
$badgeNames = @(
 'badge_first','badge_three','badge_week','badge_month','b_twoweeks',
 'b_ten','b_fifty','b_hundred','b_fullday','b_grateful',
 'b_honest','b_night','b_sunrise','b_bookend','b_closer',
 'b_comeback','b_stop','b_tamer','b_vault','b_century')
Cut-Grid 'Glossy Golden Achievement Badge Grid.png' @(0,242,484,726,968,1214) @(40,346,619,895,1260) $badgeNames $true 40 6 $true $true 3

# 3. girl animation: 6 x 3, NOT trimmed per frame, so frames line up when played
$girl = @(); 1..6 | ForEach-Object { $girl += "girl_pray_$_" }; 1..6 | ForEach-Object { $girl += "girl_read_$_" }; 1..6 | ForEach-Object { $girl += "girl_joy_$_" }
Cut-Grid 'Kawaii Faith and Joy Sprite Sheet.png' (Even 0 1536 6) (Even 0 1024 3) $girl $true 60 6 $false $false 0

# 4. illustrations: 4 x 4
$il = @('il_wake','il_scroll_bed','il_chart','il_lock_flow','il_apps_to_pray','il_clock','il_scale','il_sun_moon','il_icons_row','il_chat_megaphone','il_hello','il_phone_lock','il_night','il_morning','il_journal','il_goodbye')
# the pictures do not sit on an even grid, so the cell edges are set by hand
Cut-Grid 'Pastel Faith and Joy Sticker Grid.png' @(0,395,780,1105,1536) @(0,288,515,750,1024) $il $true 40 8 $true $false 4 $true

# 5. full-screen backgrounds: 2 x 2, white separators cropped away, no keying
Cut-Grid 'Dreamy Pastel Celebration Panels.png' @(0,512,1024) @(0,768,1536) @('bg_commit','bg_paywall','bg_bell','bg_thanks') $false 0 5 $false $false 0


# 6. clouds strip for the app background (bottom of the commit panel: clouds only)
$p = [System.Drawing.Bitmap]::FromFile((Join-Path $out 'bg_commit.png'))
$strip = $p.Clone((New-Object System.Drawing.Rectangle(0, 600, $p.Width, ($p.Height - 600))), $p.PixelFormat)
$strip.Save((Join-Path $out 'bg_clouds.png'), [System.Drawing.Imaging.ImageFormat]::Png); $strip.Dispose(); $p.Dispose()

# 7. old picture names now show the new art, so older screens update by themselves
$map = @{ 'sun'='ic_sun'; 'moon'='ic_moon'; 'lock'='ic_lock_cross'; 'unlock'='ic_unlock_cross'; 'pray'='ic_pray'; 'check'='ic_check'; 'fire'='ic_flame';
          'nav_home'='ic_home_on'; 'nav_insights'='ic_insights_on'; 'nav_locked'='ic_apps_on'; 'nav_profile'='ic_profile_on' }
foreach ($k in $map.Keys) { Copy-Item (Join-Path $out ($map[$k] + '.png')) (Join-Path $out ($k + '.png')) -Force }
Write-Host 'clouds strip and old names done'



# NOTE: assets\img\bg_sky.png was composed by hand: bg_paywall.png with clouds from bg_commit.png (rows 606+) laid over the girl from y=455, top 45 px faded in.
