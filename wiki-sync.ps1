# 지식위키 일일 동기화 (Windows 작업 스케줄러에서 매일 실행)
# 등록 작업명 예: Knowledge-Wiki-Sync
# 경로 하드코딩 없음 — 스크립트 자기 위치($PSScriptRoot)를 저장소 루트로 사용한다.
$ErrorActionPreference = 'Continue'
$root = $PSScriptRoot
$logDir = Join-Path $root "Research-Vault\_wiki\sync-logs"
New-Item -ItemType Directory -Force $logDir | Out-Null
$log = Join-Path $logDir ("sync-" + (Get-Date -Format "yyMMdd-HHmm") + ".log")

# claude CLI 탐색: PATH 우선, 없으면 VSCode 확장 번들 중 최신 버전
$claude = $null
$cmd = Get-Command claude -ErrorAction SilentlyContinue
if ($cmd) { $claude = $cmd.Source }
if (-not $claude) {
  $ext = Get-ChildItem "$env:USERPROFILE\.vscode\extensions" -Directory -Filter "anthropic.claude-code-*" -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -First 1
  if ($ext) {
    $candidate = Join-Path $ext.FullName "resources\native-binary\claude.exe"
    if (Test-Path $candidate) { $claude = $candidate }
  }
}
if (-not $claude) {
  "[$(Get-Date)] claude CLI를 찾지 못해 동기화를 건너뜀" | Out-File $log -Encoding utf8
  exit 1
}

Set-Location $root
"[$(Get-Date)] 동기화 시작 (CLI: $claude)" | Out-File $log -Encoding utf8

# 1) (GitHub 연동 시) 원격 변경 받기 — 실패해도 로컬 동기화는 계속. 미연동이면 무해하게 통과.
if (Test-Path (Join-Path $root ".git")) {
  git pull --rebase origin main 2>&1 | Out-File $log -Append -Encoding utf8
}

# 2) 위키 동기화 본 작업
$prompt = Get-Content -Raw (Join-Path $root "Research-Vault\_wiki\SYNC-PROMPT.md")
& $claude -p $prompt --permission-mode acceptEdits 2>&1 | Out-File $log -Append -Encoding utf8
"[$(Get-Date)] 위키 동기화 종료 (exit=$LASTEXITCODE)" | Out-File $log -Append -Encoding utf8

# 3) (GitHub 연동 시) 변경분 커밋·푸시
if (Test-Path (Join-Path $root ".git")) {
  git add -A 2>&1 | Out-File $log -Append -Encoding utf8
  $pending = git diff --cached --name-only
  if ($pending) {
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    git commit -m "wiki-sync: $stamp 자동 동기화" --quiet 2>&1 | Out-File $log -Append -Encoding utf8
    git push origin main 2>&1 | Out-File $log -Append -Encoding utf8
    "[$(Get-Date)] git push 완료" | Out-File $log -Append -Encoding utf8
  } else {
    "[$(Get-Date)] 변경 없음 — 커밋 생략" | Out-File $log -Append -Encoding utf8
  }
}

# 30일 지난 로그 정리
Get-ChildItem $logDir -Filter "sync-*.log" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item -Force
