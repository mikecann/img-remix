# Shared helpers kept local so installation does not need another checkout.
function Write-BatStub {
    param([string]$ToolName, [string]$Content, [string]$ToolsDir)
    $batDest = Join-Path $ToolsDir "$ToolName.bat"
    Set-Content -Path $batDest -Value $Content -Encoding ASCII
    $bashContent = @'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/__TOOL_NAME__.bat" "$@"
'@.Replace('__TOOL_NAME__', $ToolName)
    Set-Content -Path (Join-Path $ToolsDir $ToolName) -Value $bashContent -Encoding ASCII
    Write-Host "  [bat] $batDest" -ForegroundColor Green
}

# PNG-in-ICO keeps the wand's alpha channel intact (Vista and later).
function ConvertTo-Ico($pngPath, $icoPath) {
    $pngBytes = [System.IO.File]::ReadAllBytes($pngPath)
    $stream = [System.IO.FileStream]::new($icoPath, [System.IO.FileMode]::Create)
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]1)
        $writer.Write([byte]16); $writer.Write([byte]16); $writer.Write([byte]0)
        $writer.Write([byte]0); $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$pngBytes.Length); $writer.Write([uint32]22)
        $writer.Write($pngBytes)
    } finally {
        $writer.Dispose()
    }
}

function Set-MikesToolsRoot($rootKey) {
    # An existing root belongs to all installed tools. Leave its properties alone.
    if (-not (Test-Path $rootKey)) {
        New-Item -Path $rootKey -Force | Out-Null
        Set-ItemProperty -Path $rootKey -Name 'MUIVerb' -Value "Mike's Tools"
        Set-ItemProperty -Path $rootKey -Name 'SubCommands' -Value ''
        # Use a system icon so uninstalling this tool cannot break the shared root.
        Set-ItemProperty -Path $rootKey -Name 'Icon' -Value "$env:SystemRoot\System32\imageres.dll,109"
    }
}

function Add-MikesVerb($rootKey, $verbName, $label, $icon, $command) {
    $verbKey = "$rootKey\shell\$verbName"
    $cmdKey = "$verbKey\command"
    if (-not (Test-Path $cmdKey)) { New-Item -Path $cmdKey -Force | Out-Null }
    Set-ItemProperty -Path $verbKey -Name 'MUIVerb' -Value $label
    Set-ItemProperty -Path $verbKey -Name 'Icon' -Value $icon
    Set-ItemProperty -Path $cmdKey -Name '(Default)' -Value $command
}
