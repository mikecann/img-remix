# Install dependencies from this clone. Keep this safe to run more than once.
$ErrorActionPreference = 'Stop'
if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
    throw 'bun is not installed. Run winget install oven-sh.bun, then open a new terminal.'
}
# open.ts relies on Bun.spawnSync's windowsVerbatimArguments, added in Bun 1.1.4.
# Older versions ignore it and re-escape the quoted path, so explorer.exe can't find the file.
$bunVersion = "$(bun --version)".Trim()
$parsedVersion = $null
if (-not [version]::TryParse(($bunVersion -replace '[-+].*$', ''), [ref]$parsedVersion) -or $parsedVersion -lt [version]'1.1.4') {
    throw "img-remix needs Bun 1.1.4 or newer, found '$bunVersion'. Run bun upgrade, then open a new terminal."
}
Write-Host '  [bun] Installing img-remix dependencies...' -ForegroundColor DarkGray
Push-Location $PSScriptRoot
try {
    bun install --frozen-lockfile
    if ($LASTEXITCODE -ne 0) { throw "bun install failed with exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}
Write-Host '  [ok] img-remix dependencies ready.' -ForegroundColor Green
