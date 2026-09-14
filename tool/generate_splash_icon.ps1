Add-Type -AssemblyName System.Drawing

$canvasSize = 1024
$bitmap = New-Object System.Drawing.Bitmap($canvasSize, $canvasSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bitmap)

$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$g.Clear([System.Drawing.Color]::Transparent)

# Container specifications
# Android 12 safe area is inside circle of diameter ~680-700px in a 1024x1024 canvas
# A rounded square of size 640x640 with corner radius 140px fits within the 700px circle (diagonal is ~740 at sharp corners, but with 140px radius corners max distance from center is sqrt(320^2 + 180^2) ~ 367px -> diameter 734px; with size 600x600 and radius 130px, max distance is sqrt(300^2 + 170^2) = 344px -> diameter 688px, completely within circle!)
$boxSize = 600
$radius = 180
$x = ($canvasSize - $boxSize) / 2
$y = ($canvasSize - $boxSize) / 2

function Get-RoundedRectPath($x, $y, $w, $h, $r) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

# 1. Subtle soft shadow for white-on-white visibility
for ($i = 6; $i -ge 1; $i--) {
    $shadowAlpha = [int](8 * (7 - $i) / 6)
    $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($shadowAlpha, 0, 0, 0))
    $sPath = Get-RoundedRectPath ($x - $i) ($y - $i + 4) ($boxSize + $i*2) ($boxSize + $i*2) ($radius + $i)
    $g.FillPath($shadowBrush, $sPath)
    $sPath.Dispose()
    $shadowBrush.Dispose()
}

# 2. Main White Container
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
$containerPath = Get-RoundedRectPath $x $y $boxSize $boxSize $radius
$g.FillPath($whiteBrush, $containerPath)

# Subtle border for crisp definition
$borderPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(25, 0, 0, 0), 1.5)
$g.DrawPath($borderPen, $containerPath)
$borderPen.Dispose()
$containerPath.Dispose()
$whiteBrush.Dispose()

# 3. Draw original icon inside container
$src = [System.Drawing.Bitmap]::FromFile((Resolve-Path "assets\images\app_icon2.png").Path)

# Source bounding content: Left=232, Top=188, Width=578, Height=570
$srcCropRect = New-Object System.Drawing.Rectangle(232, 188, 578, 570)

# Target icon size inside container: 400x395 centered
$targetIconWidth = 400
$targetIconHeight = [int]($targetIconWidth * 570 / 578)
$destRect = New-Object System.Drawing.Rectangle(
    [int](($canvasSize - $targetIconWidth) / 2),
    [int](($canvasSize - $targetIconHeight) / 2),
    $targetIconWidth,
    $targetIconHeight
)

$g.DrawImage($src, $destRect, $srcCropRect, [System.Drawing.GraphicsUnit]::Pixel)

$src.Dispose()
$g.Dispose()

$outputPath = (Resolve-Path "assets\images").Path + "\splash_icon.png"
$bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bitmap.Dispose()

Write-Output ("Saved splash icon to " + $outputPath)
