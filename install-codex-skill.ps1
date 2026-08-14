param(
    [string]$Destination = (Join-Path $env:USERPROFILE '.codex\skills\migrate-knowledge')
)

$ErrorActionPreference = 'Stop'
$source = (Resolve-Path (Join-Path $PSScriptRoot 'skills\migrate-knowledge')).Path
$destinationPath = [System.IO.Path]::GetFullPath($Destination)
$codexSkills = [System.IO.Path]::GetFullPath((Join-Path $env:USERPROFILE '.codex\skills'))
if (-not $destinationPath.StartsWith($codexSkills, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Unsafe destination outside Codex skills: $destinationPath"
}

New-Item -ItemType Directory -Force -Path $codexSkills | Out-Null
if (Test-Path -LiteralPath $destinationPath) {
    Remove-Item -LiteralPath $destinationPath -Recurse -Force
}
Copy-Item -LiteralPath $source -Destination $destinationPath -Recurse -Force

$sourceFiles = Get-ChildItem -LiteralPath $source -Recurse -File
$targetFiles = Get-ChildItem -LiteralPath $destinationPath -Recurse -File
if ($sourceFiles.Count -ne $targetFiles.Count) { throw 'Installed file-count mismatch' }
foreach ($file in $sourceFiles) {
    $rel = $file.FullName.Substring($source.Length).TrimStart('\')
    $target = Join-Path $destinationPath $rel
    if (-not (Test-Path -LiteralPath $target)) { throw "Missing installed file: $rel" }
    if ((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash) {
        throw "Installed hash mismatch: $rel"
    }
}
Write-Output "migrate-knowledge installed and verified at $destinationPath"
