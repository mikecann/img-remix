$ErrorActionPreference = 'Stop'
$failed = $false
Get-ChildItem (Split-Path $PSScriptRoot -Parent) -Recurse -Filter '*.ps1' |
    Where-Object { $_.FullName -notmatch '[\\/]node_modules[\\/]' } |
    ForEach-Object {
        $parseErrors = $null
        $tokens = $null
        [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
        if ($parseErrors.Count) {
            $failed = $true
            $parseErrors | ForEach-Object { Write-Host $_ }
        } else { Write-Host "Parsed $($_.Name)" }
    }
if ($failed) { throw 'PowerShell parse checks failed.' }
