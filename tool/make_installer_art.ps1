# Draws every Prism icon from one vector mark: a faceted glass prism in blues
# (Prism's own drawing, not taken from any other logo).
#   windows\runner\resources\app_icon.ico                  exe / taskbar / installer icon
#   installer\art\wizard.png, wizard_small.png             the installer's pictures
#   android\app\src\main\res\mipmap-*\ic_launcher*.png     Android launcher icons
#   docs\prism-discord-icon.png                            picture for the Discord app page
# Run again after changing the mark:
#   powershell -ExecutionPolicy Bypass -File tool\make_installer_art.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'installer\art'
New-Item -ItemType Directory -Force $out | Out-Null

# Near-black of the app and the Android icon background (values\colors.xml).
$bg = [System.Drawing.Color]::FromArgb(255, 20, 19, 26)
$fg = [System.Drawing.Color]::FromArgb(255, 236, 236, 238)
$dim = [System.Drawing.Color]::FromArgb(255, 150, 150, 156)
$line = [System.Drawing.Color]::FromArgb(255, 40, 40, 46)
$amber = [System.Drawing.Color]::FromArgb(255, 255, 179, 71)
$center = New-Object System.Drawing.StringFormat
$center.Alignment = 'Center'

# The mark in a unit square: a triangular prism seen a little from the side.
# Front face split in two facets (lit and half lit), the side face in shade.
$facetLit = [System.Drawing.Color]::FromArgb(255, 196, 236, 255)
$facetHalf = [System.Drawing.Color]::FromArgb(255, 112, 196, 255)
$facetSide = [System.Drawing.Color]::FromArgb(255, 46, 120, 226)
$facetEdge = [System.Drawing.Color]::FromArgb(255, 30, 84, 178)
$A = 0.37, 0.14; $B = 0.08, 0.84; $C = 0.66, 0.84
$A2 = 0.63, 0.14; $C2 = 0.92, 0.84
$M = 0.37, 0.84

function New-Canvas([int]$w, [int]$h) {
    $bmp = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.PixelOffsetMode = 'HighQuality'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    return @($bmp, $g)
}

function Pt($p, [double]$x, [double]$y, [double]$size) {
    return New-Object System.Drawing.PointF ([single]($x + $p[0] * $size)), ([single]($y + $p[1] * $size))
}

function Fill($g, $color, $points) {
    $g.FillPolygon((New-Object System.Drawing.SolidBrush $color), [System.Drawing.PointF[]]$points)
}

# Draws the mark into the square at ($x, $y) with side $size.
function Draw-Mark($g, [double]$x, [double]$y, [double]$size) {
    $a = Pt $A $x $y $size; $b = Pt $B $x $y $size; $c = Pt $C $x $y $size
    $a2 = Pt $A2 $x $y $size; $c2 = Pt $C2 $x $y $size; $m = Pt $M $x $y $size
    Fill $g $facetSide @($a, $a2, $c2, $c)
    # A darker strip along the back edge gives the side face depth.
    $e1 = New-Object System.Drawing.PointF ([single]($a2.X - 0.05 * $size)), $a2.Y
    $e2 = New-Object System.Drawing.PointF ([single]($c2.X - 0.05 * $size)), $c2.Y
    Fill $g $facetEdge @($e1, $a2, $c2, $e2)
    Fill $g $facetHalf @($a, $b, $c)
    Fill $g $facetLit @($a, $b, $m)
}

function Rounded-Tile($g, [int]$s, [double]$radius) {
    $r = [Math]::Max(2, [int]($s * $radius))
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc(0, 0, 2 * $r, 2 * $r, 180, 90)
    $path.AddArc($s - 2 * $r - 1, 0, 2 * $r, 2 * $r, 270, 90)
    $path.AddArc($s - 2 * $r - 1, $s - 2 * $r - 1, 2 * $r, 2 * $r, 0, 90)
    $path.AddArc(0, $s - 2 * $r - 1, 2 * $r, 2 * $r, 90, 90)
    $path.CloseFigure()
    $g.FillPath((New-Object System.Drawing.SolidBrush $bg), $path)
}

function Save-Png($bmp, [string]$path) {
    New-Item -ItemType Directory -Force (Split-Path -Parent $path) | Out-Null
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

# ------------------------------------------------------------ installer art
# Side picture of the welcome and finish pages (164 x 314, drawn at 2x).
$w = 328; $h = 628
$bmp, $g = New-Canvas $w $h
$g.Clear($bg)
$g.FillRectangle((New-Object System.Drawing.SolidBrush $line), $w - 2, 0, 2, $h)
Draw-Mark $g (($w - 176) / 2) 150 176
$font = New-Object System.Drawing.Font 'Segoe UI Semibold', 40, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$g.DrawString('Prism', $font, (New-Object System.Drawing.SolidBrush $fg), (New-Object System.Drawing.RectangleF 0, 346, $w, 60), $center)
$small = New-Object System.Drawing.Font 'Segoe UI', 17, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$g.DrawString('music player', $small, (New-Object System.Drawing.SolidBrush $dim), (New-Object System.Drawing.RectangleF 0, 402, $w, 30), $center)
$g.FillEllipse((New-Object System.Drawing.SolidBrush $amber), [int]($w / 2 - 5), 452, 10, 10)
$g.Dispose()
Save-Png $bmp (Join-Path $out 'wizard.png')
$bmp.Dispose()

# Small picture at the top right of the other pages (55 x 55, drawn at 2x).
$bmp, $g = New-Canvas 110 110
$g.Clear($bg)
Draw-Mark $g 10 10 90
$g.Dispose()
Save-Png $bmp (Join-Path $out 'wizard_small.png')
$bmp.Dispose()

# ------------------------------------------------------------ Discord / docs
$bmp, $g = New-Canvas 1024 1024
$g.Clear($bg)
Draw-Mark $g 192 192 640
$g.Dispose()
Save-Png $bmp (Join-Path $root 'docs\prism-discord-icon.png')
$bmp.Dispose()

# ------------------------------------------------------------ Android
# Adaptive foreground: 108 dp canvas, the mark inside the 66 dp safe circle.
# Legacy icon (Android 7 and older launchers): the rounded tile.
$res = Join-Path $root 'android\app\src\main\res'
$densities = @{ 'mdpi' = 1.0; 'hdpi' = 1.5; 'xhdpi' = 2.0; 'xxhdpi' = 3.0; 'xxxhdpi' = 4.0 }
foreach ($d in $densities.Keys) {
    $k = $densities[$d]
    $fs = [int](108 * $k)
    $bmp, $g = New-Canvas $fs $fs
    $g.Clear([System.Drawing.Color]::Transparent)
    Draw-Mark $g (0.25 * $fs) (0.25 * $fs) (0.5 * $fs)
    $g.Dispose()
    Save-Png $bmp (Join-Path $res "mipmap-$d\ic_launcher_foreground.png")
    $bmp.Dispose()

    $ls = [int](48 * $k)
    $bmp, $g = New-Canvas $ls $ls
    $g.Clear([System.Drawing.Color]::Transparent)
    Rounded-Tile $g $ls 0.22
    Draw-Mark $g (0.14 * $ls) (0.14 * $ls) (0.72 * $ls)
    $g.Dispose()
    Save-Png $bmp (Join-Path $res "mipmap-$d\ic_launcher.png")
    $bmp.Dispose()
}

# ------------------------------------------------------------ Windows .ico
# One icon entry: PNG for 256 px, a classic 32-bit bitmap below that (every
# Windows API reads those; PNG small entries came out blurry or broken in some).
function Encode-Entry($bmp, [int]$s) {
    $ms = New-Object System.IO.MemoryStream
    if ($s -ge 256) {
        $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        return , $ms.ToArray()
    }
    $w = New-Object System.IO.BinaryWriter $ms
    $maskRow = [int]([Math]::Ceiling($s / 32.0) * 4)
    $w.Write([UInt32]40); $w.Write([Int32]$s); $w.Write([Int32](2 * $s))
    $w.Write([UInt16]1); $w.Write([UInt16]32); $w.Write([UInt32]0)
    $w.Write([UInt32]($s * $s * 4 + $maskRow * $s)); $w.Write([Int32]0); $w.Write([Int32]0); $w.Write([UInt32]0); $w.Write([UInt32]0)
    for ($y = $s - 1; $y -ge 0; $y--) {
        for ($x = 0; $x -lt $s; $x++) {
            $c = $bmp.GetPixel($x, $y)
            $w.Write([byte]$c.B); $w.Write([byte]$c.G); $w.Write([byte]$c.R); $w.Write([byte]$c.A)
        }
    }
    $w.Write((New-Object byte[] ($maskRow * $s)))
    $w.Flush()
    return , $ms.ToArray()
}

$sizes = 16, 20, 24, 32, 40, 48, 64, 128, 256
$pngs = @()
foreach ($s in $sizes) {
    $bmp, $g = New-Canvas $s $s
    $g.Clear([System.Drawing.Color]::Transparent)
    if ($s -le 32) {
        # Tray / title bar / small taskbar: the mark alone, as big as it goes.
        Draw-Mark $g 0 ($s * 0.02) $s
    } else {
        Rounded-Tile $g $s 0.22
        Draw-Mark $g ($s * 0.12) ($s * 0.12) ($s * 0.76)
    }
    $g.Dispose()
    $pngs += , (Encode-Entry $bmp $s)
    $bmp.Dispose()
}
$ico = New-Object System.IO.MemoryStream
$wr = New-Object System.IO.BinaryWriter $ico
$wr.Write([UInt16]0); $wr.Write([UInt16]1); $wr.Write([UInt16]$sizes.Count)
$offset = 6 + 16 * $sizes.Count
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $s = $sizes[$i]
    $wr.Write([byte]($(if ($s -ge 256) { 0 } else { $s })))
    $wr.Write([byte]($(if ($s -ge 256) { 0 } else { $s })))
    $wr.Write([byte]0); $wr.Write([byte]0)
    $wr.Write([UInt16]1); $wr.Write([UInt16]32)
    $wr.Write([UInt32]$pngs[$i].Length); $wr.Write([UInt32]$offset)
    $offset += $pngs[$i].Length
}
foreach ($p in $pngs) { $wr.Write($p) }
$wr.Flush()
[System.IO.File]::WriteAllBytes((Join-Path $root 'windows\runner\resources\app_icon.ico'), $ico.ToArray())

Get-ChildItem $out, (Join-Path $root 'windows\runner\resources\app_icon.ico'), (Join-Path $root 'docs\prism-discord-icon.png') | Select-Object Name, Length
