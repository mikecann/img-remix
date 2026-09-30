# Install this clone's CLI and Explorer verb. No administrator rights needed.
param(
    [switch]$SkipDeps,
    [string]$ToolsDir = 'C:\dev\tools',
    [switch]$SkipPathCheck
)
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Use install.sh on macOS.' }
. (Join-Path $PSScriptRoot 'install-lib.ps1')
if (-not $SkipDeps) { & (Join-Path $PSScriptRoot 'deps.ps1') }

if (-not $SkipPathCheck) {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $onPath = ($machinePath -split ';') + ($userPath -split ';') |
        Where-Object { $_.TrimEnd('\') -ieq $ToolsDir.TrimEnd('\') }
    if (-not $onPath) {
        $answer = Read-Host "Add '$ToolsDir' to your User PATH? [Y/n]"
        if ($answer -eq '' -or $answer -imatch '^y') {
            $newPath = (([string]$userPath).TrimEnd(';') + ";$ToolsDir").TrimStart(';')
            [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
            $env:PATH += ";$ToolsDir"
            Write-Host 'Open a new terminal to use the command.' -ForegroundColor Yellow
        }
    }
}
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
Write-BatStub 'img-remix' @"
@echo off
bun run "$PSScriptRoot\index.ts" %*
"@ $ToolsDir

$iconsDir = Join-Path $env:LOCALAPPDATA 'img-remix\icons'
New-Item -ItemType Directory -Path $iconsDir -Force | Out-Null
$icon = Join-Path $iconsDir 'img-remix.ico'
ConvertTo-Ico (Join-Path $PSScriptRoot 'icons\wand.png') $icon
$imageExts = @('.jpg', '.jpeg', '.png', '.webp', '.bmp', '.tiff', '.tif')
foreach ($ext in $imageExts) {
    $root = "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\MikesTools"
    Set-MikesToolsRoot $root
    $command = 'cmd.exe /k ""{0}\img-remix.bat" "%1""' -f $ToolsDir.TrimEnd('\')
    Add-MikesVerb $root 'ImgRemix' 'img-remix' $icon $command
}
Write-Host "Installed img-remix from $PSScriptRoot" -ForegroundColor Green
Write-Host 'Set OPENROUTER_API_KEY in .env beside index.ts before generating images.'
