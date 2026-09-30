# This touches HKCU. Run only on an ephemeral Windows CI runner.
$ErrorActionPreference = 'Stop'
if ($env:CI -ne 'true') { throw 'Run this installer smoke test only on an ephemeral CI runner.' }
$repoDir = Split-Path $PSScriptRoot -Parent
$tempDir = Join-Path ([IO.Path]::GetTempPath()) ('img-remix test ' + [guid]::NewGuid())
$toolsDir = Join-Path $tempDir 'tools'
$oldLocalAppData = $env:LOCALAPPDATA
$root = 'HKCU:\Software\Classes\SystemFileAssociations\.png\shell\MikesTools'
$neighbor = "$root\shell\SplitTestNeighbor"
function Assert($condition, $message) { if (-not $condition) { throw $message } }
try {
    $env:LOCALAPPDATA = $tempDir
    New-Item -Path $neighbor -Force | Out-Null
    Set-ItemProperty $neighbor -Name 'MUIVerb' -Value 'Keep this tool'
    Set-ItemProperty $root -Name 'MUIVerb' -Value 'Existing shared menu'
    & (Join-Path $repoDir 'install.ps1') -SkipDeps -SkipPathCheck -ToolsDir $toolsDir
    & (Join-Path $repoDir 'install.ps1') -SkipDeps -SkipPathCheck -ToolsDir $toolsDir
    Assert ((Get-ItemProperty $root).MUIVerb -eq 'Existing shared menu') 'Installer changed the shared menu.'
    Assert ((Get-ItemProperty $neighbor).MUIVerb -eq 'Keep this tool') 'Installer changed another verb.'
    $bat = Join-Path $toolsDir 'img-remix.bat'
    Assert ((Get-Content $bat -Raw).Contains("$repoDir\index.ts")) 'Stub points at the wrong clone.'
    Assert (([IO.File]::ReadAllBytes($bat) | Where-Object { $_ -gt 127 }).Count -eq 0) 'Stub is not ASCII.'
    Assert (Test-Path (Join-Path $tempDir 'img-remix\icons\img-remix.ico')) 'Missing converted icon.'
    foreach ($ext in @('.jpg', '.jpeg', '.png', '.webp', '.bmp', '.tiff', '.tif')) {
        $verb = "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\MikesTools\shell\ImgRemix"
        Assert ((Get-ItemProperty $verb).MUIVerb -eq 'img-remix') "Wrong label for $ext"
        $expected = 'cmd.exe /k ""{0}\img-remix.bat" "%1""' -f $toolsDir
        Assert ((Get-ItemProperty "$verb\command").'(Default)' -eq $expected) "Wrong command for $ext"
    }
    & (Join-Path $repoDir 'uninstall.ps1') -ToolsDir $toolsDir
    & (Join-Path $repoDir 'uninstall.ps1') -ToolsDir $toolsDir
    Assert (Test-Path $neighbor) 'Uninstaller removed another verb.'
    Assert (Test-Path $root) 'Uninstaller removed the shared submenu.'
    Assert (-not (Test-Path $bat)) 'Uninstaller left the bat stub.'
    Assert (-not (Test-Path (Join-Path $toolsDir 'img-remix'))) 'Uninstaller left the bash stub.'
    Assert (-not (Test-Path (Join-Path $tempDir 'img-remix\icons\img-remix.ico'))) 'Uninstaller left the icon.'
    foreach ($ext in @('.jpg', '.jpeg', '.png', '.webp', '.bmp', '.tiff', '.tif')) {
        Assert (-not (Test-Path "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\MikesTools\shell\ImgRemix")) "Uninstaller left $ext verb."
    }
    Write-Host 'Windows installer smoke checks passed.'
} finally {
    Remove-Item $neighbor -Recurse -Force -ErrorAction SilentlyContinue
    $env:LOCALAPPDATA = $oldLocalAppData
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
}
