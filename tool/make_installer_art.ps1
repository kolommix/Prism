# Draws Prism's Windows pictures from the Prism mark (docs\prism-discord-icon.png):
#   installer\art\wizard.png, wizard_small.png   the installer's pictures
#   windows\runner\resources\app_icon.ico        the exe / taskbar / installer icon
# Black and white like the app, the amber dot as the only extra color.
# Run again after changing the mark:
#   powershell -ExecutionPolicy Bypass -File tool\make_installer_art.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'installer\art'
New-Item -ItemType Directory -Force $out | Out-Null
$mark = [System.Drawing.Image]::FromFile((Join-Path $root 'docs\prism-discord-icon.png'))
# The dots sit inside this square of the 1024 px source.
$markRect = New-Object System.Drawing.Rectangle 150, 150, 724, 724

function New-Canvas([int]$w, [int]$h) {
    $bmp = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.PixelOffsetMode = 'HighQuality'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    return @($bmp, $g)
}

function Draw-Mark($g, [int]$x, [int]$y, [int]$size) {
    $g.DrawImage($mark, (New-Object System.Drawing.Rectangle $x, $y, $size, $size), $markRect, [System.Drawing.GraphicsUnit]::Pixel)
}

# Same near-black as the mark's own background, so it blends in.
$bg = $mark.GetPixel(4, 4)
$fg = [System.Drawing.Color]::FromArgb(255, 236, 236, 238)
$dim = [System.Drawing.Color]::FromArgb(255, 150, 150, 156)
$line = [System.Drawing.Color]::FromArgb(255, 40, 40, 46)
$amber = [System.Drawing.Color]::FromArgb(255, 255, 179, 71)
$center = New-Object System.Drawing.StringFormat
$center.Alignment = 'Center'

# Side picture of the welcome and finish pages (164 x 314, drawn at 2x).
$w = 328; $h = 628
$bmp, $g = New-Canvas $w $h
$g.Clear($bg)
$g.FillRectangle((New-Object System.Drawing.SolidBrush $line), $w - 2, 0, 2, $h)
Draw-Mark $g ([int](($w - 176) / 2)) 150 176
$font = New-Object System.Drawing.Font 'Segoe UI Semibold', 40, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$g.DrawString('Prism', $font, (New-Object System.Drawing.SolidBrush $fg), (New-Object System.Drawing.RectangleF 0, 346, $w, 60), $center)
$small = New-Object System.Drawing.Font 'Segoe UI', 17, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
$g.DrawString('music player', $small, (New-Object System.Drawing.SolidBrush $dim), (New-Object System.Drawing.RectangleF 0, 402, $w, 30), $center)
$g.FillEllipse((New-Object System.Drawing.SolidBrush $amber), [int]($w / 2 - 5), 452, 10, 10)
$g.Dispose()
$bmp.Save((Join-Path $out 'wizard.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# Small picture at the top right of the other pages (55 x 55, drawn at 2x).
$bmp, $g = New-Canvas 110 110
$g.Clear($bg)
Draw-Mark $g 8 8 94
$g.Dispose()
$bmp.Save((Join-Path $out 'wizard_small.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# app_icon.ico: rounded dark tile with the mark, PNG-compressed sizes 16-256.
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
        # Tray / title bar / small taskbar sizes: the scaled-down mark is a
        # blur of tiny dots there. Draw its 12 main dots directly instead
        # (4 x 4 grid without corners, big ones in the middle), no tile.
        $cell = $s / 4.0
        $c1 = [System.Drawing.Color]::FromArgb(255, 165, 200, 255)
        $c2 = [System.Drawing.Color]::FromArgb(255, 51, 221, 255)
        for ($row = 0; $row -lt 4; $row++) {
            for ($col = 0; $col -lt 4; $col++) {
                $corner = ($row -eq 0 -or $row -eq 3) -and ($col -eq 0 -or $col -eq 3)
                if ($corner) { continue }
                $inner = ($row -eq 1 -or $row -eq 2) -and ($col -eq 1 -or $col -eq 2)
                $rad = if ($inner) { $cell * 0.47 } else { $cell * 0.33 }
                $t = ($row + $col) / 6.0
                $col3 = [System.Drawing.Color]::FromArgb(255,
                    [int]($c1.R + ($c2.R - $c1.R) * $t), [int]($c1.G + ($c2.G - $c1.G) * $t), [int]($c1.B + ($c2.B - $c1.B) * $t))
                $cx = ($col + 0.5) * $cell; $cy = ($row + 0.5) * $cell
                $g.FillEllipse((New-Object System.Drawing.SolidBrush $col3), [single]($cx - $rad), [single]($cy - $rad), [single](2 * $rad), [single](2 * $rad))
            }
        }
        $g.Dispose()
        $pngs += , (Encode-Entry $bmp $s)
        $bmp.Dispose()
        continue
    }
    $r = [Math]::Max(2, [int]($s * 0.22))
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc(0, 0, 2 * $r, 2 * $r, 180, 90)
    $path.AddArc($s - 2 * $r - 1, 0, 2 * $r, 2 * $r, 270, 90)
    $path.AddArc($s - 2 * $r - 1, $s - 2 * $r - 1, 2 * $r, 2 * $r, 0, 90)
    $path.AddArc(0, $s - 2 * $r - 1, 2 * $r, 2 * $r, 90, 90)
    $path.CloseFigure()
    $g.FillPath((New-Object System.Drawing.SolidBrush $bg), $path)
    # Small sizes get a bigger mark: the dots must stay visible.
    $pad = if ($s -le 24) { [int]($s * 0.04) } else { [int]($s * 0.1) }
    Draw-Mark $g $pad $pad ($s - 2 * $pad)
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
$mark.Dispose()

Get-ChildItem $out, (Join-Path $root 'windows\runner\resources\app_icon.ico') | Select-Object Name, Length
