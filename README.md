# Knowledge-Wiki Starter

연구 노트를 **잊지 않고 누적 활용**하는 개인 지식백과 시스템 템플릿. Andrej Karpathy의 [llm-wiki 패턴](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)을 Claude Code 위에서 구현했다.

핵심 아이디어: 매 질문마다 원본 문서를 다시 읽지 않는다. LLM이 **합성 위키**를 유지·갱신하고, 질문에는 그 위키로 답한다. 지식은 대화가 아니라 파일에 쌓이므로 세션이 끝나도, 다른 기기에서도 살아남는다.

## 3층 구조

| 층 | 폴더 | 성격 |
|---|---|---|
| 원본 소스 | `Research-Vault/<주제볼트>/` | **불변**. 날짜 파일명 노트 + 원문 PDF |
| 합성 지식 | `Research-Vault/_wiki/` | LLM이 유지하는 개념 페이지. 소스 추가 시마다 갱신 |
| 데이터 카탈로그 | `Research-Vault/_data-registry/` | 노트에 등장한 데이터 출처의 구조화 색인 |

## ⚠️ 먼저: 노트는 어떻게 만들어지나

이 템플릿은 **합성·기억 층**(위키)이다. 그 아래에 노트를 **생산하는 층** — 무엇을 읽고 어떻게 날짜 노트로 저장할지 — 이 있어야 위키가 채워진다. 위키는 노트를 읽고 종합할 뿐, 노트를 스스로 만들지 않는다.

**그래서 셋업 시 "수집·작성 워크플로우"를 먼저 정의해야 한다.** 방법과 검증된 예시 패턴(2-모드 Scout/Commit, 채점 기준, 중복 방지)은 [`Research-Vault/_wiki/NOTE-WORKFLOW.md`](Research-Vault/_wiki/NOTE-WORKFLOW.md)에 정리돼 있다. 손으로 노트를 써도 되고 자동화해도 되지만, "무엇을 읽고 어떻게 저장하는가"를 한 번은 정해 둬야 한다.

## 무엇이 들어 있나

- `Research-Vault/_wiki/NOTE-WORKFLOW.md` — **수집·작성 워크플로우를 먼저 정의하는 법** (무엇을 읽고 어떻게 노트로 저장할지)
- `Research-Vault/_wiki/WIKI-RULES.md` — 시스템의 단일 규칙서 (개념 페이지 형식, 모순 처리 ⚔️, 데이터 질문 응답 프로토콜, lint)
- `Research-Vault/_wiki/SYNC-PROMPT.md` — 일일 동기화가 수행하는 작업 정의
- `Research-Vault/_wiki/INDEX.md`, `INGEST-LOG.md` — 개념 색인 / 통합 완료 장부 (빈 골격)
- `Research-Vault/_data-registry/DATA-SOURCES.md` — 데이터 출처 마스터 테이블 (빈 골격)
- `wiki-sync.ps1` — 매일 새 노트를 위키에 통합하는 동기화 스크립트 (자기 위치 자동 인식)
- `.claude/commands/migrate-knowledge.md` — 외부 폴더 산출물을 지식저장소로 통합하는 슬래시 명령어
- `CLAUDE.md` — 이 폴더에서 여는 모든 Claude Code 세션이 따르는 운영 규칙
- `SETUP.md` — **받은 사람이 자기 환경에 맞게 초기화하는 지침 (AI가 읽고 자동 수행)**

콘텐츠(실제 연구 노트·개념 페이지)는 포함되어 있지 않다. 빈 골격이다.

## 셋업 (쉬운 길)

1. 이 저장소를 클론한 폴더를 Claude Code(VSCode 확장/데스크톱 앱)로 연다.
2. Claude에게 말한다: **"SETUP.md를 읽고 이 템플릿을 내 환경에 맞게 초기화해줘"**
3. Claude가 묻는 것에 답한다 — 연구 주제(볼트) 이름, **수집·작성 워크플로우**(무엇을 읽고 어떻게 저장할지), 일일 동기화 시각, GitHub 저장소 생성 여부. 나머지(폴더 생성·경로 치환·작업 스케줄러 등록)는 Claude가 처리한다.

## 셋업 (수동)

`SETUP.md`의 단계를 직접 따라 한다 — ① `<주제볼트>` 폴더 생성, ② `CLAUDE.md`·`WIKI-RULES.md`의 `<...>` 자리표시자 치환, ③ Windows 작업 스케줄러에 `wiki-sync.ps1` 일일 등록, ④ (선택) 비공개 GitHub 저장소 생성·푸시.

## 일일 자동화

작업 스케줄러가 매일 `wiki-sync.ps1`을 실행한다: 새로 추가된 노트를 탐지 → 관련 개념 페이지 갱신(모순은 삭제하지 않고 ⚔️로 양쪽 보존) → 데이터 출처 등록 → (GitHub 연동 시) 자동 커밋·푸시. 미통합 노트 판정은 `INGEST-LOG.md`(장부)와 실제 폴더의 차집합으로 한다.

## 요구 환경

- Windows + Claude Code (VSCode 확장 또는 데스크톱 앱). 동기화 스크립트는 확장 번들 `claude.exe`를 자동 탐색한다.
- (선택) GitHub 계정 — 백업·모바일 조회·협업용.

---

원리: Karpathy, *The LLM-Wiki Pattern* — https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
