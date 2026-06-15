# CLAUDE.md — 지식저장소 루트 지침

이 폴더는 주제 볼트(`Research-Vault/<주제볼트들>`)와 그 위의 **합성 지식층**으로 구성된다. 출력 언어: `<출력언어>`.
※ 셋업 시 `<주제볼트들>`·`<출력언어>` 자리표시자를 실제 값으로 치환할 것 (SETUP.md 참조).

## 지식위키 우선 원칙 (모든 세션 공통)

운영 규칙의 단일 출처는 `Research-Vault/_wiki/WIKI-RULES.md`다. 모든 세션은 다음을 따른다:

1. **지식 질문** → 원본 노트 전수 검색 전에 `Research-Vault/_wiki/INDEX.md`에서 관련 개념 페이지를 먼저 읽는다. 재사용 가치 있는 종합 답변은 `_wiki/qa/`에 적립한다.
2. **데이터 출처 질문** → `Research-Vault/_data-registry/DATA-SOURCES.md` 조회 → free/registration이면 즉시 다운로드해 `Research-Vault/_downloads/`에 저장하고 경로 제공. 없으면 웹 검색 후 레지스트리에 적립 (WIKI-RULES §4).
3. **새 노트 생성 시** → 관련 개념 페이지 1~3개 갱신 + 새 데이터 출처 등록 + `_wiki/INGEST-LOG.md`에 기록 (WIKI-RULES §2). 모순 발견 시 삭제하지 말고 ⚔️로 양쪽 보존.
4. **원본 노트(날짜 파일명)는 위키 작업 중 수정 금지.**

## 외부 산출물 통합

다른 폴더의 리서치 산출물은 `/migrate-knowledge <폴더경로> [메모]`로 `Research-Vault/Project-Knowledge/`에 통합한다 (절차: `.claude/commands/migrate-knowledge.md`). 이 폴더는 일일 동기화 자동 탐지 대상이 아니므로, 통합과 INGEST-LOG 기록을 같은 세션에서 수행한다.

## 자동화

작업 스케줄러가 매일 `wiki-sync.ps1`을 실행한다 (git 연동 시: pull → 동기화 → 커밋·푸시). 실행 기록: `_wiki/sync-logs/`. 상세는 WIKI-RULES §6.
