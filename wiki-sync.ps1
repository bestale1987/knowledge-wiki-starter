[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$SkipPush
)

# Generic fail-closed wiki sync runner for Codex on Windows.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = [System.IO.Path]::GetFullPath($PSScriptRoot)
$promptPath = Join-Path $root 'Research-Vault\_wiki\SYNC-PROMPT.md'
$logDir = Join-Path $root 'Research-Vault\_wiki\sync-logs'
$lockPath = Join-Path ([System.IO.Path]::GetTempPath()) 'knowledge-wiki-sync.lock'
$lockStream = $null
$exitCode = 0

New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir ('sync-' + (Get-Date -Format 'yyMMdd-HHmmss') + '.log')

function Write-Log([string]$Message) {
    $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $script:log -Value $line -Encoding UTF8
    Write-Host $line
}

function Invoke-Git([string[]]$GitArgs) {
    # Windows PowerShell 5.1 wraps native stderr as ErrorRecord objects. With
    # the script-wide Stop policy, even a successful Git warning can throw.
    # Lower the policy only for this native call and decide success by its exit code.
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& git -C $script:root @GitArgs 2>&1)
        $nativeExit = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($nativeExit -ne 0) { throw "git $($GitArgs -join ' ') failed (exit=$nativeExit)" }
    return $output
}

function Get-Changes {
    $rows = @(Invoke-Git @('-c', 'core.quotepath=false', 'status', '--porcelain=v1', '--untracked-files=all'))
    $result = @()
    foreach ($rowObject in $rows) {
        $row = [string]$rowObject
        if ([string]::IsNullOrWhiteSpace($row)) { continue }
        $result += [pscustomobject]@{ Code = $row.Substring(0, 2); Path = $row.Substring(3) }
    }
    return $result
}

function Test-AllowedPath([string]$Path) {
    return (
        $Path -match '^Research-Vault/_wiki/(INDEX\.md|INGEST-LOG\.md)$' -or
        $Path -match '^Research-Vault/_wiki/(concepts|qa)/[^/]+\.md$' -or
        $Path -match '^Research-Vault/_data-registry/DATA-SOURCES\.md$' -or
        $Path -match '^Research-Vault/_data-registry/sources/[^/]+\.md$'
    )
}

try {
    try {
        $lockStream = [System.IO.File]::Open($lockPath, 'OpenOrCreate', 'ReadWrite', 'None')
    } catch {
        throw "Another wiki sync is already running: $lockPath"
    }

    Write-Log "sync start (DryRun=$DryRun, SkipPush=$SkipPush)"
    if (-not (Test-Path -LiteralPath $promptPath)) { throw "Missing prompt: $promptPath" }
    if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) { throw 'Git repository is required' }

    $branch = ([string](Invoke-Git @('branch', '--show-current') | Select-Object -First 1)).Trim()
    if ($branch -ne 'main') { throw "Expected main branch, found $branch" }
    if (@(Get-Changes).Count -ne 0) { throw 'Working tree must be clean' }

    Invoke-Git @('fetch', '--quiet', 'origin', '+refs/heads/main:refs/remotes/origin/main') | Out-Null
    $baseline = ([string](Invoke-Git @('rev-parse', 'HEAD') | Select-Object -First 1)).Trim()
    $origin = ([string](Invoke-Git @('rev-parse', 'refs/remotes/origin/main') | Select-Object -First 1)).Trim()
    if ($baseline -ne $origin) { throw 'Local main must equal origin/main' }
    $indexTree = ([string](Invoke-Git @('write-tree') | Select-Object -First 1)).Trim()

    if ($DryRun) {
        Write-Log 'dry run passed; no Codex, commit, or push performed'
    } else {
        $codex = Get-Command 'codex.cmd' -ErrorAction SilentlyContinue
        if (-not $codex) { $codex = Get-Command 'codex' -ErrorAction SilentlyContinue }
        if (-not $codex) { throw 'Codex CLI not found' }

        $prompt = Get-Content -LiteralPath $promptPath -Raw
        $prompt | & $codex.Source exec -c service_tier=flex -C $root --sandbox workspace-write --ephemeral --color never - 2>&1 |
            Tee-Object -FilePath $log -Append | Out-Host
        $agentExit = $LASTEXITCODE
        if ($agentExit -ne 0) { throw "Codex failed with exit $agentExit" }

        $afterHead = ([string](Invoke-Git @('rev-parse', 'HEAD') | Select-Object -First 1)).Trim()
        $afterIndex = ([string](Invoke-Git @('write-tree') | Select-Object -First 1)).Trim()
        if ($afterHead -ne $baseline -or $afterIndex -ne $indexTree) { throw 'Codex changed Git HEAD or index' }

        $changes = @(Get-Changes)
        foreach ($change in $changes) {
            if ($change.Code.Contains('D') -or $change.Code.Contains('R') -or $change.Code.Contains('C')) {
                throw "Delete, rename, or copy is not allowed: $($change.Path)"
            }
            if (-not (Test-AllowedPath $change.Path)) { throw "Unexpected change: $($change.Path)" }
        }

        if ($changes.Count -eq 0) {
            Write-Log 'no wiki changes'
        } else {
            Invoke-Git @('fetch', '--quiet', 'origin', '+refs/heads/main:refs/remotes/origin/main') | Out-Null
            $originNow = ([string](Invoke-Git @('rev-parse', 'refs/remotes/origin/main') | Select-Object -First 1)).Trim()
            if ($originNow -ne $origin) { throw 'origin/main changed during sync' }

            $paths = @($changes | ForEach-Object { $_.Path } | Sort-Object -Unique)
            foreach ($path in $paths) { Invoke-Git @('add', '--', $path) | Out-Null }
            Invoke-Git @('commit', '-m', ('wiki-sync: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm'))) | Out-Null
            if (-not $SkipPush) { Invoke-Git @('push', 'origin', 'HEAD:refs/heads/main') | Out-Null }
            Write-Log "committed $($paths.Count) derived files"
        }
    }
} catch {
    $exitCode = 1
    Write-Log "failed: $($_.Exception.Message)"
} finally {
    if ($lockStream) { $lockStream.Dispose() }
    Get-ChildItem -LiteralPath $logDir -Filter 'sync-*.log' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

exit $exitCode
