# SETUP — 템플릿 초기화 지침 (AI 수행용)

> 사용자가 "이 템플릿을 초기화/셋업해줘"라고 하면, Claude는 이 문서를 읽고 아래를 순서대로 수행한다. 각 단계에서 사용자에게 필요한 값을 묻고, 되돌리기 어려운 작업(저장소 생성·스케줄러 등록) 전에는 확인한다.

## 0. 현재 위치 확인
- 이 저장소가 클론된 폴더의 **절대경로**를 확인한다. 이것이 앞으로의 `VAULT_ROOT`다.

## 1. 사용자에게 물을 것
1. **연구 주제(볼트) 이름** 1~5개 — 예: "AI-Finance", "Bio-Regulation". 각각 `Research-Vault/<이름>/` 폴더가 된다.
2. **일일 동기화 시각** — 기본 17:40 제안.
3. **GitHub 저장소**를 만들지 — 백업·모바일 조회를 원하면 예 (공개/비공개도 확인).
4. **출력 언어** — 위키·요약을 어떤 언어로 쓸지 (기본: 사용자가 대화하는 언어).

## 2. 폴더 생성
- 각 주제 볼트 폴더 `Research-Vault/<이름>/`를 만든다.
- 원본 노트 파일명 규칙을 정한다 (기본: `YYMMDD-식별자.md`). 이 규칙을 `WIKI-RULES.md`와 `SYNC-PROMPT.md`의 노트 탐지 정규식에 반영한다.

## 2-1. 수집·작성 워크플로우 정의 (중요 — 빠뜨리지 말 것)
- 위키는 노트를 **읽기만** 한다. 노트를 **생산하는** 워크플로우가 없으면 위키는 빈 채로 남는다.
- `Research-Vault/_wiki/NOTE-WORKFLOW.md`를 읽고, 사용자와 함께 각 볼트의 워크플로우 4요소를 정해 **볼트 폴더의 `CLAUDE.md`(또는 별도 SKILL 문서)에 적는다**:
  1. 무엇을 읽는가 (소스 풀·주기), 2. 어떻게 거르는가 (필터·채점 기준), 3. 어떻게 저장하는가 (노트 작성 규칙·파일명), 4. 언제 실행하는가 (수동/스케줄).
- 사용자가 막연해하면 NOTE-WORKFLOW.md의 2-모드(Scout/Commit) 예시를 출발점으로 제안한다.

## 3. 자리표시자 치환
다음 파일에서 `<...>` 자리표시자를 사용자 값으로 바꾼다:
- `CLAUDE.md` — `<주제볼트들>`을 실제 볼트 이름 목록으로, `<출력언어>`를 지정 언어로.
- `Research-Vault/_wiki/WIKI-RULES.md` — `<주제볼트들>` 치환, 노트 파일명 정규식 확정.
- `Research-Vault/_wiki/SYNC-PROMPT.md` — 볼트 폴더 목록과 탐지 규칙 확정.
- `wiki-sync.ps1` — **경로 치환 불필요** ($PSScriptRoot로 자기 위치를 자동 인식). claude.exe도 자동 탐색하므로 그대로 둔다.

## 4. 일일 동기화 등록 (Windows 작업 스케줄러)
사용자 확인 후, PowerShell로 작업을 등록한다 (`<HH:mm>`, `<VAULT_ROOT>`는 실제 값):
```powershell
$action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "<VAULT_ROOT>\wiki-sync.ps1"'
$trigger = New-ScheduledTaskTrigger -Daily -At "<HH:mm>"
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 40)
Register-ScheduledTask -TaskName "Knowledge-Wiki-Sync" -Action $action -Trigger $trigger -Settings $settings
```
- 등록 후 `INGEST-LOG.md`가 존재하는지 확인한다. 빈 골격이라도 있어야 동기화가 동작한다(없으면 안전하게 종료하도록 설계됨).

## 5. (선택) GitHub 비공개 저장소
- `gh`가 없으면 설치 안내. `gh auth login`으로 인증.
- `<VAULT_ROOT>`에서 `git init -b main` → `.gitignore` 확인(PDF·_downloads·sync-logs 제외) → 첫 커밋 → `gh repo create <이름> --private --source . --remote origin --push`.
- 비공개 설정을 `gh repo view --json visibility`로 검증해 사용자에게 보고.
- 협업: `gh repo add-collaborator` 또는 저장소 Settings → Collaborators로 특정인 초대.

## 6. (선택) 글로벌 마이그레이션 명령어
- 사용자가 "다른 폴더에서도 마이그레이션을 쓰고 싶다"고 하면, `.claude/commands/migrate-knowledge.md`를 사용자 레벨(`~/.claude/commands/`)로 복사하고 그 안의 `VAULT` 경로를 `<VAULT_ROOT>` 절대경로로 바꾼다.

## 7. 첫 노트 안내
- 사용자에게: 이제 각 볼트 폴더에 `YYMMDD-주제.md` 형식으로 노트를 쌓고, 질문은 이 폴더에서 연 세션에서 하면 위키가 우선 참조된다고 안내. 외부 산출물은 `/migrate-knowledge <폴더>`로 통합.
- 마지막으로 이 `SETUP.md`는 삭제하거나 그대로 둬도 무방하다고 안내.
