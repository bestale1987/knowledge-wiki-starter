# WIKI-RULES.md — 지식 위키 운영 규칙 (스키마)

> Karpathy의 llm-wiki 패턴 기반. 원본 노트(소스층)는 불변, 이 위키(합성층)는 LLM이 유지·갱신한다.
> 이 파일은 위키를 읽거나 쓰는 모든 세션이 먼저 읽어야 하는 규칙이다.
> ※ 셋업 시 `<주제볼트들>`을 실제 볼트 폴더 이름으로 치환할 것.

---

## 1. 3층 구조

| 층 | 위치 | 성격 |
|---|---|---|
| 원본 소스 | `<주제볼트들>`의 날짜 노트 + `_pdfs/` | **불변**. 위키 작업 중 절대 수정하지 않는다 |
| 합성 지식 | `_wiki/concepts/`, `_wiki/qa/` | LLM이 유지. 새 소스가 들어올 때마다 갱신 |
| 데이터 카탈로그 | `_data-registry/` | 노트에 등장한 모든 데이터 출처의 구조화된 색인 |

다운로드한 실제 데이터셋은 `_downloads/<source-slug>/`에 저장한다.

### 1.1 지식 그래프 레이블

새 합성 문서에는 통제 어휘를 사용한다. `node_type`은 `SourceNote`, `Concept`, `Claim`, `QA`, `DataSource`, `Entity` 중 하나다. 관계는 `SUPPORTS`, `CONTRADICTS`, `QUALIFIES`, `EXTENDS`, `SUPERSEDES`, `DEPENDS_ON`을 기본으로 하고, 필요할 때만 `CITES`, `ABOUT`, `USES_DATA`를 쓴다.

### 1.2 불변 소스와 파생 지식 lifecycle

- 날짜 원본 노트와 PDF는 불변이며 삭제·덮어쓰기·대체하지 않는다.
- lifecycle은 개념·주장·Q&A 같은 파생 문서에만 적용한다.
- `status`는 `active`, `superseded`, `withdrawn`, `invalidated`, `duplicate` 중 하나다.
- 비활성 파생 문서에는 `superseded_by` 또는 후속 링크, `replacement_reason`, `reviewed_at`을 기록한다. 새 문서에는 필요할 때 `supersedes`를 기록한다.
- 검색은 기본적으로 `active`를 사용하고 비활성 문서는 후속 링크를 따라간다.
- 더 강한 후속 답변이 나와도 원본 노트를 지우지 않고, 앞선 합성 답변만 비활성화하며 관련 링크를 수선한다.

## 2. 개념 페이지 (`_wiki/concepts/<slug>.md`)

- 단위: **주제 개념** (예: a-topic-subtheme). 기관·저자 단위 페이지는 만들지 않는다.
- 총 15~25개 수준으로 유지. 새 개념 추가는 기존 페이지로 흡수 불가능할 때만.
- 신규 또는 다음 대규모 갱신부터 필수 frontmatter: `type: wiki-concept`, `node_type: Concept`, `status: active`, `slug`, `updated` (YYYY-MM-DD), `sources_count`, `vaults`
- `sources_count`는 소스 노트 파일 수가 아니라 **고유 원출처 수**다. 동일 보고서를 다룬 복수 노트를 모두 남길 때 두 번째 이후 소스 목록 항목에는 `<!-- source-count: exclude -->`를 붙여 중복 집계에서 제외한다.
- 필수 섹션:
  1. **핵심 결론 (Living Summary)** — 현재 시점의 종합 판단을 3~7개 핵심 문단으로 구조화한다. 각 문단은 하나의 판단과 근거 경계를 쉬운 언어로 설명하고, 상세 역사·수치·반례는 쟁점별 정리로 내린다.
  2. **쟁점별 정리** — 소스 간 **합의 ✅ / 대립 ⚔️ / 단일소스 ⚠️** 를 명시. 모든 주장에 `[[원본노트]]` 링크
  3. **핵심 수치** — 표. 수치마다 출처 노트 링크
  4. **데이터 출처** — 이 개념 관련 데이터셋 → `[[_data-registry/sources/...]]` 링크
  5. **소스 노트 목록** — 날짜순
  6. **미해결 질문**

### 갱신 규칙 (Ingest)
새 노트가 추가되면: 관련 개념 페이지(보통 1~3개)를 읽고 → 새 주장을 쟁점별 정리에 통합 → 기존 결론과 **모순되면 ⚔️로 표시하고 둘 다 보존** (삭제 금지) → Living Summary를 다시 쓰고 `updated`/`sources_count` 갱신.

## 3. Q&A 적립 (`_wiki/qa/`)

여러 노트를 종합해 답했고 그 답이 재사용 가치가 있으면 `qa/YYMMDD-질문-슬러그.md`로 저장하고 관련 개념 페이지의 미해결 질문/쟁점에 반영한다. Q&A에는 `node_type: QA`, `status: active`, `updated`를 둔다. 단순 조회성 답변은 저장하지 않는다. 더 강한 후속 답변은 이전 Q&A를 삭제하지 않고 `superseded` 처리한다.

## 4. 데이터 레지스트리 (`_data-registry/`)

- `DATA-SOURCES.md` — 마스터 테이블 (이름, 무엇, 접근등급, URL)
- `sources/<slug>.md` — 출처별 상세. 필수: **무엇 / 커버리지(기간·지역·빈도) / 접근 등급(free·registration·subscription·report-embedded) / 다운로드 방법(정확한 URL+절차) / 인용 노트 `[[링크]]`**

### 데이터 질문 응답 프로토콜
"이런 데이터 어디서 찾지?" 질문에:
1. `DATA-SOURCES.md`에서 후보 검색 → 상세 페이지 확인
2. `free`/`registration`이면 **즉시 다운로드 시도** → `_downloads/<slug>/`에 저장 후 경로 제공
3. `subscription`이면 접근 경로·라이선스·무료 대안 안내
4. 레지스트리에 없으면 웹 검색으로 찾고, 결과를 **레지스트리에 새 페이지로 적립**

## 5. Lint (월 1회 권장)

- 개념 페이지 `updated`가 오래됐는데 그 사이 관련 노트가 추가됨 → 갱신 누락
- 어느 개념 페이지에도 연결되지 않은 고아 노트 탐지
- ⚔️ 대립 중 후속 소스로 해소된 것 정리
- 비활성 파생 문서에 후속 링크가 있는지 검사
- 통제 어휘 밖의 레이블·관계·상태가 생겼는지 검사
- 레지스트리 URL 생존 확인

## 6. 일일 자동 동기화

작업 스케줄러가 매일 `wiki-sync.ps1`을 실행한다. PC가 꺼져 있었으면 다음 부팅 시 보충 실행(StartWhenAvailable).
- 동기화 로직: `_wiki/SYNC-PROMPT.md`
- 통합 추적: `_wiki/INGEST-LOG.md` — 위키에 통합 완료된 노트의 전체 목록. **이 장부와 실제 폴더의 차집합이 "미통합 노트"의 유일한 판정 기준**이다. 위키를 갱신한 모든 세션은 INGEST-LOG에도 해당 노트를 기록해야 한다.
- 실행 기록: `_wiki/sync-logs/`

## 7. 금지 사항

- 원본 노트 수정 (위키 작업 중)
- 출처 링크 없는 주장 추가
- 모순 발견 시 한쪽 삭제 (양쪽 보존 + ⚔️ 표시가 원칙)
- 날짜 원본 노트에 lifecycle을 적용해 대체하거나 삭제
- 통제 어휘와 의미가 겹치는 임의 레이블·관계 신설
- 개념 페이지 무분별한 신설 (25개 초과 시 통합 먼저 검토)
