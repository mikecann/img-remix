param([string]$ToolsDir = 'C:\dev\tools')
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Use uninstall.sh on macOS.' }
# Never remove the shared submenu or another tool's verbs.
foreach ($ext in @('.jpg', '.jpeg', '.png', '.webp', '.bmp', '.tiff', '.tif')) {
    $verb = "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\MikesTools\shell\ImgRemix"
    if (Test-Path $verb) { Remove-Item -Path $verb -Recurse -Force }
}
foreach ($name in @('img-remix.bat', 'img-remix')) {
    $path = Join-Path $ToolsDir $name
    if (Test-Path $path) { Remove-Item -Path $path -Force }
}
$icon = Join-Path $env:LOCALAPPDATA 'img-remix\icons\img-remix.ico'
if (Test-Path $icon) { Remove-Item $icon -Force }
Write-Host 'Removed img-remix launchers and Explorer entries. The clone and .env are kept.'
