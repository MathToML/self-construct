---
name: alfred:9-update
description: MoAI-ADK 패키지 및 템플릿 업데이트 (백업 자동 생성, 설정 파일 보존)
argument-hint: [--check|--force|--check-quality]
allowed-tools:
  - Bash(npm:*)
  - Bash(pnpm:*)
  - Bash(yarn:*)
  - Bash(bun:*)
  - Bash(chmod:*)
  - Bash(mkdir:*)
  - Bash(ls:*)
  - Read
  - Write
  - Grep
  - Glob
---

# 🔄 MoAI-ADK 프로젝트 업데이트

## 커맨드 개요

MoAI-ADK npm 패키지를 최신 버전으로 업데이트하고, 템플릿 파일(`.claude`, `.moai`, `CLAUDE.md`)을 안전하게 갱신합니다. 자동 백업, 설정 파일 보존, 무결성 검증을 지원합니다.

**✅ 버전 요구사항**: v0.2.18 이상

**🔒 사용자 데이터 보호**:
- v0.2.18부터 `.moai/specs/`, `.moai/reports/` 디렉토리가 **자동으로 보호**됩니다
- 사용자가 생성한 SPEC 파일과 리포트가 **절대 덮어써지지 않습니다**

**📌 v0.2.17 이하 사용자**:
- 터미널에서 `moai init .` 명령어를 사용하세요:
  ```bash
  # v0.2.17 이하 권장 방법
  npm install -g moai-adk@latest
  cd your-project
  moai init .
  ```

## 실행 흐름

1. **버전 확인** - 현재/최신 버전 비교
2. **백업 생성** - 타임스탬프 기반 자동 백업
3. **패키지 업데이트** - npm install moai-adk@latest
4. **템플릿 복사** - Claude Code 도구 기반 안전한 파일 복사
5. **검증** - 파일 존재 및 내용 무결성 확인

## Alfred 오케스트레이션

**실행 방식**: Alfred가 직접 실행 (전문 에이전트 위임 없음)
**예외 처리**: 오류 발생 시 `debug-helper` 자동 호출
**품질 검증**: 선택적으로 `trust-checker` 연동 가능 (--check-quality 옵션)

## 사용법

사용자가 다음과 같이 커맨드를 실행할 수 있습니다:
- `/alfred:9-update` - 업데이트 확인 및 실행
- `/alfred:9-update --check` - 업데이트 가능 여부만 확인
- `/alfred:9-update --force` - 강제 업데이트 (백업 없이)
- `/alfred:9-update --check-quality` - 업데이트 후 TRUST 검증 수행

## 실행 절차

### Phase 1: 버전 확인 및 검증

Alfred는 다음 작업을 수행합니다:

1. **현재 버전 확인**: 프로젝트에 설치된 moai-adk 버전을 확인합니다
2. **최신 버전 조회**: npm 레지스트리에서 최신 버전을 조회합니다
3. **버전 비교**: 현재 버전과 최신 버전을 비교하여 업데이트 필요 여부를 판단합니다

**조건부 실행**: `--check` 옵션이 제공되면 여기서 중단하고 결과만 보고합니다

### Phase 2: 백업 생성

Alfred는 다음 작업을 수행합니다:

1. **백업 디렉토리 생성**: `.moai-backup/` 디렉토리에 타임스탬프 기반 서브 디렉토리를 생성합니다 (형식: YYYY-MM-DD-HH-mm-ss)
2. **파일 백업**: `.claude/`, `.moai/`, `CLAUDE.md`를 백업 디렉토리에 복사합니다
3. **백업 확인**: 백업이 성공적으로 생성되었는지 확인합니다

**백업 구조**: `.moai-backup/YYYY-MM-DD-HH-mm-ss/{.claude, .moai, CLAUDE.md}`

**예외**: `--force` 옵션이 제공되면 백업 단계를 건너뜁니다

### Phase 3: npm 패키지 업데이트

Alfred는 다음 작업을 수행합니다:

1. **패키지 관리자 자동 감지**:
   - 프로젝트 루트에서 lock 파일을 확인하여 사용 중인 패키지 관리자를 감지합니다
   - `pnpm-lock.yaml` 존재 → pnpm 사용
   - `yarn.lock` 존재 → yarn 사용
   - `bun.lockb` 존재 → bun 사용
   - 그 외 → npm 사용 (기본값)

2. **로컬 vs 글로벌 설치 판단**:
   - `package.json` 파일이 존재하면 로컬 설치를 수행합니다
   - `package.json` 파일이 없으면 글로벌 설치를 수행합니다

3. **패키지 업데이트 실행**:
   - 감지된 패키지 관리자로 `moai-adk@latest`를 설치합니다
   - 예: `pnpm install moai-adk@latest` 또는 `npm install -g moai-adk@latest`

4. **설치 확인**:
   - 설치가 성공적으로 완료되었는지 확인합니다
   - 설치 후 버전을 다시 확인하여 최신 버전이 설치되었는지 검증합니다

### Phase 4: Alfred가 Claude Code 도구로 템플릿 복사/병합

**담당**: Alfred (직접 실행, 에이전트 위임 없음)
**도구**: Bash, Glob, Read, Grep, Write

**처리 방식**:
- Step 2-6: 시스템 파일 (명령어, 에이전트, 훅, 스타일, 가이드) → **전체 교체** ✅
- Step 7-9: 프로젝트 문서 (product, structure, tech) → **사용자 수정 시 보존** 🔒
- Step 10: CLAUDE.md → **지능형 병합** 🔄
- Step 11: config.json → **스마트 딥 병합** 🔄

**병렬 실행 최적화** ⚡:
- **Step 2-5 병렬 처리**: 명령어/에이전트/훅/Output Styles 파일 복사는 독립적이므로 동시 실행
- **기대 효과**: 4단계 → 1단계로 단축 (약 75% 시간 절감)
- **Step 6-11 순차 처리**: 병합 로직과 의존성이 있는 작업은 순차 실행 유지

**실행 절차**:

#### Step 1: npm root 확인

Alfred는 다음 작업을 수행합니다:

1. **node_modules 경로 확인**: `npm root` 명령을 실행하여 node_modules 디렉토리의 절대 경로를 확인합니다
2. **템플릿 경로 설정**: 확인된 경로를 기반으로 템플릿 루트 경로를 설정합니다 (`{npm_root}/moai-adk/templates`)
3. **템플릿 존재 확인**: 템플릿 디렉토리가 실제로 존재하는지 확인합니다

**사용자 데이터 보호 (User Data Protection)** 🔒:

Alfred는 다음 디렉토리를 **절대 건드리지 않습니다**:
- `.moai/specs/` - 사용자가 생성한 모든 SPEC 파일
  - ❌ 읽기 금지, ❌ 수정 금지, ❌ 삭제 금지
  - 템플릿 복사 시 자동 제외 (`excludePaths: ['specs']`)
- `.moai/reports/` - 동기화 리포트 및 작업 이력
  - ❌ 읽기 금지, ❌ 수정 금지, ❌ 삭제 금지
  - 템플릿 복사 시 자동 제외 (`excludePaths: ['reports']`)

**보존/병합 대상**:
- `.moai/config.json` - 프로젝트 설정 (스마트 병합) 🔄
- `.moai/project/*.md` - 프로젝트 문서 (사용자 수정 시 보존) 🔒
- `CLAUDE.md` - 프로젝트 지침 (지능형 병합) 🔄

---

#### Step 2: 명령어 파일 복사 (카테고리 A)

**대상**: `.claude/commands/alfred/*.md` (~10개 파일)

Alfred는 다음 작업을 수행합니다:

1. **템플릿 파일 검색**: 템플릿 디렉토리에서 모든 명령어 파일을 검색합니다 (경로: `{npm_root}/moai-adk/templates/.claude/commands/alfred/*.md`)
2. **각 파일 복사**: 검색된 모든 명령어 파일을 프로젝트의 `.claude/commands/alfred/` 디렉토리에 복사합니다
   - 템플릿 파일을 읽습니다
   - 프로젝트 디렉토리에 동일한 파일명으로 작성합니다
   - 각 파일 복사 성공 시 확인 메시지를 출력합니다
3. **완료 확인**: 모든 파일 복사가 완료되면 전체 완료 메시지를 출력합니다

**오류 처리**:
- 템플릿 디렉토리를 찾을 수 없으면 경로 확인이 필요하다는 경고를 출력합니다
- 파일 쓰기에 실패하면 필요한 디렉토리를 생성한 후 재시도합니다

---

#### Step 3: 에이전트 파일 복사 (카테고리 B)

**대상**: `.claude/agents/alfred/*.md` (~9개 파일)

Alfred는 Step 2와 동일한 절차를 수행하며, 대상 경로만 `.claude/agents/alfred/`로 변경됩니다.

---

#### Step 4: 훅 파일 복사 + 권한 부여 (카테고리 C)

**대상**: `.claude/hooks/alfred/*.cjs` (~4개 파일)

Alfred는 다음 작업을 수행합니다:

1. **템플릿 파일 검색**: 템플릿 디렉토리에서 모든 훅 파일을 검색합니다 (경로: `{npm_root}/moai-adk/templates/.claude/hooks/alfred/*.cjs`)
2. **각 파일 복사**: 검색된 모든 훅 파일을 프로젝트의 `.claude/hooks/alfred/` 디렉토리에 복사합니다
3. **실행 권한 부여**: Unix 계열 시스템에서 훅 파일에 실행 권한(755)을 부여합니다
   - 성공 시: 권한 부여 완료 메시지를 출력합니다
   - 실패 시: Windows 환경에서는 정상이므로 경고만 출력하고 계속 진행합니다
4. **완료 확인**: 모든 작업이 완료되면 전체 완료 메시지를 출력합니다

**권한 설정**:
- Unix 계열: `755` (rwxr-xr-x)
- Windows: chmod 실패해도 경고만 출력

---

#### Step 5: Output Styles 복사 (카테고리 D) ✨

**대상**: `.claude/output-styles/alfred/*.md` (4개 파일)

Alfred는 Step 2와 동일한 절차를 수행하며, 대상 경로만 `.claude/output-styles/alfred/`로 변경됩니다.

---

#### Step 6: 개발 가이드 복사 (카테고리 E)

**대상**: `.moai/memory/development-guide.md` (무조건 덮어쓰기)

Alfred는 다음 작업을 수행합니다:

1. **템플릿 파일 읽기**: 템플릿 디렉토리에서 development-guide.md 파일을 읽습니다
2. **파일 쓰기**: 프로젝트의 `.moai/memory/` 디렉토리에 파일을 작성합니다
   - 쓰기 실패 시 필요한 디렉토리를 생성한 후 재시도합니다
3. **완료 확인**: 업데이트 완료 메시지를 출력합니다

**참고**: development-guide.md는 항상 최신 템플릿으로 덮어씁니다 (사용자 수정 금지)

---

#### Step 7-9: 프로젝트 문서 복사 (카테고리 F-H) - 사용자 작업물 보존

**대상**:
- `.moai/project/product.md`
- `.moai/project/structure.md`
- `.moai/project/tech.md`

Alfred는 각 파일마다 다음 절차를 반복합니다:

1. **기존 파일 존재 확인**: 프로젝트에 해당 파일이 이미 존재하는지 확인합니다
   - 파일이 없으면 5단계(새로 생성)로 이동합니다
   - 파일이 있으면 2단계로 진행합니다

2. **템플릿 상태 검증**: 파일에 `self-construct` 패턴이 존재하는지 확인합니다
   - 패턴이 있으면 템플릿 상태로 판단하여 5단계(덮어쓰기)로 이동합니다
   - 패턴이 없으면 사용자가 수정한 상태로 판단하여 3단계(보존)로 진행합니다

3. **사용자 작업물 보존** 🔒: 사용자가 수정한 파일은 보존합니다
   - 파일을 건너뛴다는 정보 메시지를 출력합니다
   - 최신 템플릿 참조 경로를 안내합니다
   - 필요 시 수동으로 새 필드를 추가할 수 있다고 안내합니다
   - 복사하지 않고 다음 파일로 이동합니다

4. **(예비 단계 - 현재 미사용)**

5. **새 템플릿 복사**: 템플릿 상태이거나 파일이 없는 경우 최신 템플릿으로 복사합니다
   - 템플릿 파일을 읽습니다
   - 프로젝트 디렉토리에 파일을 작성합니다
   - 쓰기 실패 시 필요한 디렉토리를 생성한 후 재시도합니다

6. **완료 메시지**: 상황에 맞는 완료 메시지를 출력합니다
   - 템플릿 상태였던 경우: 최신 버전으로 업데이트됨
   - 사용자 수정 상태였던 경우: 사용자 작업물 보존됨
   - 새로 생성한 경우: 새로 생성됨

**보호 정책**:
- `self-construct` 패턴 존재 → 템플릿 상태, 안전하게 덮어쓰기
- 패턴 없음 → **사용자 수정, 보존 (덮어쓰지 않음)** 🔒
- 파일 없음 → 새로 생성

---

#### Step 10: CLAUDE.md 병합 (카테고리 I) - 지능형 병합

**대상**: `CLAUDE.md` (프로젝트 루트)

**병합 전략**: 템플릿 최신 구조 + 사용자 프로젝트 정보 유지

Alfred는 다음 절차를 수행합니다:

1. **기존 파일 존재 확인**: 프로젝트에 CLAUDE.md 파일이 이미 존재하는지 확인합니다
   - 파일이 없으면 6단계(새로 생성)로 이동합니다
   - 파일이 있으면 2단계로 진행합니다

2. **템플릿 상태 검증**: 파일에 `self-construct` 패턴이 존재하는지 확인합니다
   - 패턴이 있으면 템플릿 상태로 판단하여 6단계(덮어쓰기)로 이동합니다
   - 패턴이 없으면 사용자가 수정한 상태로 판단하여 3단계(병합)로 진행합니다

3. **사용자 프로젝트 정보 추출**: 기존 CLAUDE.md에서 프로젝트 정보를 추출합니다
   - 프로젝트 이름, 설명, 버전, 모드 정보를 추출합니다
   - 추출된 정보를 확인 메시지로 출력합니다

4. **최신 템플릿 읽기**: 템플릿 디렉토리에서 최신 CLAUDE.md 파일을 읽어 메모리에 저장합니다

5. **템플릿에 사용자 정보 주입**: 템플릿의 플레이스홀더를 사용자 정보로 교체합니다
   - `self-construct` → 추출된 프로젝트 이름
   - `A self-construct project built with MoAI-ADK` → 추출된 설명
   - `0.1.0` → 추출된 버전
   - `team` → 추출된 모드
   - 병합된 내용을 프로젝트 루트에 작성합니다
   - 병합 완료 메시지를 출력합니다

6. **새 템플릿 복사**: 템플릿 상태이거나 파일이 없는 경우 최신 템플릿으로 복사합니다
   - 템플릿 파일을 읽습니다
   - 프로젝트 루트에 파일을 작성합니다

7. **완료 메시지**: 상황에 맞는 완료 메시지를 출력합니다
   - 템플릿 상태였던 경우: 최신 버전으로 업데이트됨
   - 병합한 경우: 템플릿 최신화 + 프로젝트 정보 유지됨
   - 새로 생성한 경우: 새로 생성됨

**병합 정책**:
- 템플릿 상태 → 전체 교체
- 사용자 수정 → **지능형 병합** 🔄
  - 템플릿 최신 구조 사용
  - 프로젝트 정보(이름, 설명, 버전, 모드) 유지
  - Alfred 에이전트 목록, 워크플로우 등은 최신 템플릿 반영
- 파일 없음 → 새로 생성

---

#### Step 11: config.json 병합 (카테고리 J) - 스마트 병합

**대상**: `.moai/config.json` (프로젝트 설정)

**병합 전략**: 템플릿 최신 구조 + 사용자 설정값 유지

Alfred는 다음 절차를 수행합니다:

1. **기존 파일 존재 확인**: 프로젝트에 config.json 파일이 이미 존재하는지 확인합니다
   - 파일이 없으면 7단계(새로 생성)로 이동합니다
   - 파일이 있으면 2단계로 진행합니다

2. **템플릿 상태 검증**: 파일에 `self-construct` 패턴이 존재하는지 확인합니다
   - 패턴이 있으면 템플릿 상태로 판단하여 7단계(덮어쓰기)로 이동합니다
   - 패턴이 없으면 사용자가 설정한 상태로 판단하여 3단계(병합)로 진행합니다

3. **사용자 설정값 추출**: 기존 config.json에서 사용자 설정값을 추출합니다
   - JSON을 파싱하여 프로젝트 정보, 품질 기준, Git 전략, TAG 카테고리, 진행 단계 등을 추출합니다
   - 추출된 정보를 확인 메시지로 출력합니다

4. **최신 템플릿 읽기**: 템플릿 디렉토리에서 최신 config.json 파일을 읽어 JSON으로 파싱합니다

5. **딥 병합 수행**: 템플릿과 사용자 설정을 필드별로 지능적으로 병합합니다
   - **project**: 사용자 값을 100% 유지합니다 (프로젝트 식별 정보)
   - **constitution**: 템플릿의 최신 필드를 가져온 후 사용자가 수정한 값으로 덮어씁니다
   - **git_strategy**: 사용자 값을 100% 유지합니다 (워크플로우 설정)
   - **tags.categories**: 템플릿과 사용자 카테고리를 합친 후 중복을 제거합니다
   - **pipeline**: 템플릿의 명령어 목록을 사용하되, 진행 상태는 사용자 값을 유지합니다
   - **_meta**: 템플릿의 최신 메타데이터를 사용합니다

6. **병합 결과 저장**: 병합된 JSON을 들여쓰기 2칸으로 포맷하여 파일에 작성합니다
   - 병합 완료 메시지를 출력합니다

7. **새 템플릿 복사**: 템플릿 상태이거나 파일이 없는 경우 최신 템플릿으로 복사합니다
   - 템플릿 파일을 읽습니다
   - 프로젝트 디렉토리에 파일을 작성합니다

8. **완료 메시지**: 상황에 맞는 완료 메시지를 출력합니다
   - 템플릿 상태였던 경우: 최신 버전으로 업데이트됨
   - 병합한 경우: 스마트 병합 (템플릿 구조 + 사용자 설정) 완료됨
   - 새로 생성한 경우: 새로 생성됨

**병합 정책** (필드별):

| 필드                                | 병합 전략              | 이유               |
| ----------------------------------- | ---------------------- | ------------------ |
| `project.*`                         | 사용자 값 100% 유지    | 프로젝트 식별 정보 |
| `constitution.test_coverage_target` | 사용자 값 유지         | 팀 정책            |
| `constitution.simplicity_threshold` | 사용자 값 유지         | 팀 정책            |
| `git_strategy.*`                    | 사용자 값 100% 유지    | 워크플로우 설정    |
| `tags.categories`                   | 병합 (템플릿 + 사용자) | 확장 가능          |
| `pipeline.available_commands`       | 템플릿 최신            | 시스템 명령어      |
| `pipeline.current_stage`            | 사용자 값 유지         | 진행 상태          |
| `_meta.*`                           | 템플릿 최신            | TAG 참조           |

---

**전체 오류 처리 원칙**:
- 각 Step별 독립적 오류 처리
- 한 파일 실패가 전체 프로세스를 중단시키지 않음
- 실패한 파일 목록 수집하여 Phase 4 종료 후 보고
- 디렉토리 없음 → `mkdir -p` 자동 실행 후 재시도
- JSON 파싱 실패 → 백업 생성 후 템플릿으로 교체 (안전 모드)

### Phase 5: 업데이트 검증

**담당**: Alfred (직접 실행)
**도구**: Bash, Glob, Read, Grep

**검증 항목**:

#### 5.1 파일 개수 검증 (동적)

Alfred는 다음 검증을 수행합니다:

1. **명령어 파일 개수 확인**: `.claude/commands/alfred/` 디렉토리의 `.md` 파일 개수를 확인합니다 (예상: ~10개)
   - 실제 개수가 예상보다 적으면 누락 경고를 출력합니다

2. **에이전트 파일 개수 확인**: `.claude/agents/alfred/` 디렉토리의 `.md` 파일 개수를 확인합니다 (예상: ~9개)

3. **훅 파일 개수 확인**: `.claude/hooks/alfred/` 디렉토리의 `.cjs` 파일 개수를 확인합니다 (예상: ~4개)

4. **Output Styles 파일 개수 확인**: `.claude/output-styles/alfred/` 디렉토리의 `.md` 파일 개수를 확인합니다 (예상: 4개)

5. **프로젝트 문서 개수 확인**: `.moai/project/` 디렉토리의 `.md` 파일 개수를 확인합니다 (예상: 3개)

6. **필수 파일 존재 확인**: development-guide.md와 CLAUDE.md 파일이 존재하는지 확인합니다
   - 파일이 없으면 필수 파일 누락 오류를 출력합니다

**파일 개수 기준**: 템플릿에서 기대하는 파일 개수와 실제 복사된 파일 개수를 비교하여, 누락 감지 시 Phase 4 재실행을 제안합니다

---

#### 5.2 YAML Frontmatter 검증

Alfred는 다음 검증을 수행합니다:

1. **샘플 파일 선택**: 대표 명령어 파일(예: 1-spec.md)을 선택합니다
2. **Frontmatter 추출**: 파일의 첫 10줄을 읽어 YAML 블록을 추출합니다
3. **YAML 파싱 시도**: `---`로 감싸진 YAML 블록을 파싱합니다
   - 파싱 실패 시: YAML frontmatter 손상 경고를 출력합니다
   - 파싱 성공 시: 검증 통과 메시지를 출력합니다
4. **필수 필드 확인**: name, description, tools(또는 allowed-tools) 필드가 존재하는지 확인합니다

**검증 방식**: 대표 파일 1-2개를 샘플링하여 YAML 구문 오류를 감지하고, 손상 시 Phase 4 재실행을 제안합니다

---

#### 5.3 버전 정보 확인

Alfred는 다음 검증을 수행합니다:

1. **development-guide.md 버전 확인**: development-guide.md 파일에서 version 정보를 추출합니다
2. **package.json 버전 확인**: 설치된 moai-adk 패키지의 버전을 확인합니다
3. **버전 일치 확인**: 두 버전이 일치하는지 비교합니다
   - 일치하면: 버전 정합성 통과 메시지를 출력합니다
   - 불일치하면: 버전 불일치 경고를 출력합니다

**버전 불일치 시**: Phase 3 재실행(npm 재설치) 또는 Phase 4 재실행(템플릿 재복사)을 제안합니다

---

#### 5.4 훅 파일 권한 검증 (Unix 계열만)

Alfred는 다음 검증을 수행합니다:

1. **훅 파일 권한 확인**: `.claude/hooks/alfred/` 디렉토리의 `.cjs` 파일 권한을 확인합니다
2. **실행 권한 검증**: 파일에 실행 권한(`x`)이 있는지 확인합니다 (예상: 755, rwxr-xr-x)

**권한 확인**: Unix 계열 시스템에서만 수행하며, Windows 환경에서는 검증을 생략합니다

---

**검증 실패 시 자동 복구 전략**:

| 오류 유형     | 복구 조치                      |
| ------------- | ------------------------------ |
| 파일 누락     | Phase 4 재실행 제안            |
| 버전 불일치   | Phase 3 재실행 제안 (npm)      |
| 내용 손상     | 백업 복원 후 재시작 제안       |
| 권한 오류     | chmod 재실행 ([Bash] chmod +x) |
| 디렉토리 없음 | mkdir -p 후 Phase 4 재실행     |

### Phase 5.5: 품질 검증 (선택적)

**조건**: `--check-quality` 옵션이 제공된 경우에만 실행

**도구**: trust-checker 에이전트

Alfred는 다음 절차를 수행합니다:

1. **trust-checker 에이전트 호출**: Level 1 빠른 스캔을 수행하도록 trust-checker 에이전트를 호출합니다 (3-5초 소요)

2. **TRUST 5원칙 검증**: 다음 항목들을 검증합니다
   - **T**est: 테스트 커버리지가 85% 이상인지 확인
   - **R**eadable: ESLint/Biome 린터 검사 통과 여부
   - **U**nified: TypeScript 타입 안전성
   - **S**ecured: npm audit를 통한 보안 취약점 검사
   - **T**rackable: @TAG 체인 무결성 검증

3. **결과별 처리**:
   - **✅ Pass (통과)**: 업데이트 성공 완료
     - 품질 검증 통과 메시지를 출력합니다
     - 모든 파일이 정상이고 시스템 무결성이 유지됨을 확인합니다

   - **⚠️ Warning (경고)**: 경고 표시 후 완료
     - 품질 검증 경고 메시지를 출력합니다
     - 일부 문서 포맷 이슈나 권장사항 미적용 항목을 안내합니다
     - 사용자 확인을 권장하지만 계속 진행 가능합니다

   - **❌ Critical (치명적)**: 롤백 제안
     - 품질 검증 실패 메시지를 출력합니다
     - 파일 손상이나 설정 불일치를 안내합니다
     - 사용자에게 조치를 선택하도록 제안합니다:
       1. 롤백 (권장): `moai restore .moai-backup/{timestamp}` 실행
       2. 무시하고 진행 (위험): 손상된 상태로 완료

**실행 시간**: 추가 3-5초 (Level 1 빠른 스캔)

**검증 생략**: `--check-quality` 옵션이 없으면 Phase 5.5를 건너뛰고 완료합니다

---

## 아키텍처: Alfred 중앙 오케스트레이션

```
┌─────────────────────────────────────────────────────────┐
│                   UpdateOrchestrator                     │
├─────────────────────────────────────────────────────────┤
│ Phase 1: VersionChecker   (자동 - Bash)                  │
│ Phase 2: BackupManager    (자동 - Bash)                  │
│ Phase 3: NpmUpdater       (자동 - Bash)                  │
│ Phase 4: ⏸️  ALFRED 직접 실행 (Claude Code 도구)        │
│          Glob, Read, Grep, Write, Bash                  │
│ Phase 5: UpdateVerifier   (자동 - Alfred 직접)           │
│          Glob, Read, Grep, Bash                         │
│ Phase 5.5: trust-checker  (선택 - @agent)               │
└─────────────────────────────────────────────────────────┘
```

**핵심 원칙**:
- **Phase 1-3**: Alfred가 Bash 명령을 실행하여 버전 확인, 백업, npm 업데이트를 자동으로 수행합니다
- **Phase 4**: Alfred가 Claude Code 도구를 사용하여 템플릿 복사 및 병합을 직접 제어합니다
- **Phase 5**: Alfred가 Claude Code 도구를 사용하여 업데이트 결과를 검증합니다
- **Phase 5.5**: 선택적으로 trust-checker 에이전트를 호출하여 품질 검증을 수행합니다
- **자연어 지침**: 모든 로직이 자연어 지침으로 표현되어 있습니다
- **코드 최소화**: TypeScript 코드 블록 대신 Claude Code 도구만 사용합니다

## 출력 예시

```text
🔍 MoAI-ADK 업데이트 확인 중...
📦 현재 버전: v0.0.1
⚡ 최신 버전: v0.0.2
✅ 업데이트 가능

💾 백업 생성 중...
   → .moai-backup/2025-10-02-15-30-00/

📦 패키지 업데이트 중...
   npm install moai-adk@latest
   ✅ 패키지 업데이트 완료

📄 Phase 4: Alfred가 템플릿 복사/병합 중...
   ✅ .claude/commands/alfred/ (~10개 파일 복사 완료)
   ✅ .claude/agents/alfred/ (~9개 파일 복사 완료)
   ✅ .claude/hooks/alfred/ (4개 파일 복사 + 권한 설정 완료)
   ✅ .claude/output-styles/alfred/ (4개 파일 복사 완료)
   ✅ .moai/memory/development-guide.md (무조건 업데이트)
   ✅ .moai/project/product.md (템플릿 → 최신 버전)
   ⏭️  .moai/project/structure.md (사용자 작업물 보존)
   ✨ .moai/project/tech.md (새로 생성)
   🔄 CLAUDE.md (템플릿 최신화 + 프로젝트 정보 유지)
   🔄 .moai/config.json (스마트 병합: 템플릿 구조 + 사용자 설정)
   ✅ 템플릿 파일 처리 완료

🔍 검증 중...
   [Bash] npm list moai-adk@0.0.2 ✅
   ✅ 검증 완료

✨ 업데이트 완료!

롤백이 필요하면: moai restore .moai-backup/2025-10-02-15-30-00
```

## 고급 옵션

### --check-quality (선택)

업데이트 후 TRUST 5원칙 품질 검증을 추가로 수행합니다.

`/alfred:9-update --check-quality` 옵션을 사용하여 실행합니다.

**상세 내용**: Phase 5.5 섹션 참조
**실행 시간**: 추가 3-5초 (Level 1 빠른 스캔)
**검증 결과**: Pass / Warning / Critical

### --check (확인만)

업데이트 가능 여부만 확인하고 실제 업데이트는 수행하지 않습니다.

`/alfred:9-update --check` 옵션을 사용하여 확인합니다.

### --force (강제 업데이트)

백업 생성 없이 강제 업데이트합니다. **주의**: 롤백 불가능합니다.

`/alfred:9-update --force` 옵션을 사용하여 실행합니다.

## 안전 장치

**자동 백업**:
- `--force` 옵션 없으면 항상 백업 생성
- 백업 위치: `.moai-backup/YYYY-MM-DD-HH-mm-ss/`
- 수동 삭제 전까지 영구 보존

**데이터 보호 전략** (✨ v0.2.18+):

1. **완전 보존 (Never Touch)** 🔒:
   - `.moai/specs/` - **사용자 SPEC 파일 절대 건드리지 않음**
     - 읽기 ❌, 수정 ❌, 삭제 ❌, 덮어쓰기 ❌
     - `moai init .` 실행 시: 자동 제외 (`excludePaths: ['specs']`)
     - `/alfred:9-update` 실행 시: Alfred가 명시적으로 제외
     - 백업 생성 시에도 제외 (불필요)
   - `.moai/reports/` - **동기화 리포트 절대 건드리지 않음**
     - 읽기 ❌, 수정 ❌, 삭제 ❌, 덮어쓰기 ❌
     - `moai init .` 실행 시: 자동 제외 (`excludePaths: ['reports']`)
     - `/alfred:9-update` 실행 시: Alfred가 명시적으로 제외
   - `.moai/project/*.md` - 프로젝트 문서 (사용자 수정 시 보존)
     - `self-construct` 패턴 없으면 사용자 수정으로 간주

2. **지능형 병합** 🔄:
   - **CLAUDE.md**: 템플릿 최신 구조 + 프로젝트 정보 유지
     - 프로젝트 이름, 설명, 버전, 모드 추출 → 템플릿 주입
     - Alfred 에이전트 목록, 워크플로우는 최신 템플릿 반영

   - **.moai/config.json**: 스마트 딥 병합
     - `project.*` → 사용자 값 100% 유지
     - `constitution.*` → 사용자 정책 유지, 새 필드는 템플릿 기본값
     - `git_strategy.*` → 사용자 워크플로우 완전 보존
     - `tags.categories` → 템플릿 + 사용자 추가 카테고리 병합
     - `pipeline.available_commands` → 템플릿 최신 명령어
     - `pipeline.current_stage` → 사용자 진행 상태 유지

3. **템플릿 판단 기준**:
   - `self-construct` 패턴 존재 → 템플릿 상태 (전체 교체)
   - 패턴 없음 → 사용자 수정 (보존 또는 병합)

**롤백 지원**:
백업 목록을 확인하려면 `.moai-backup/` 디렉토리를 조회하고, 특정 백업을 복원하려면 `moai restore .moai-backup/2025-10-02-15-30-00` 명령을 사용합니다.
**주의**: 복원 시 기존 파일을 덮어씁니다. 신중히 선택하세요.

## 오류 복구 시나리오

### 시나리오 1: 파일 복사 실패

**상황**:
```text
Phase 4 실행 중...
  → [Write] .claude/commands/alfred/1-spec.md ✅
  → [Write] .claude/commands/alfred/2-build.md ❌ (디스크 공간 부족)
```

**복구 절차**:
```text
[Step 1] 오류 로그 기록
  → "❌ 2-build.md 복사 실패: 디스크 공간 부족"

[Step 2] 실패 파일 목록에 추가
  → failed_files = [2-build.md]

[Step 3] 나머지 파일 계속 복사
  → Phase 4 중단 없이 진행
  → 모든 파일 처리 완료까지 계속

[Step 4] Phase 4 종료 후 실패 목록 보고
  → "⚠️ {count}개 파일 복사 실패: [2-build.md]"

[Step 5] 사용자 선택
  → "재시도" → Phase 4 재실행 (실패한 파일만)
  → "백업 복원" → moai restore .moai-backup/{timestamp}
  → "무시" → Phase 5로 진행 (불완전한 상태, 권장하지 않음)
```

**자동 재시도**:
- 각 파일당 최대 2회 재시도
- 재시도 후에도 실패 시 건너뛰고 계속 진행

---

### 시나리오 2: 검증 실패 (파일 누락)

**상황**:
```text
Phase 5 검증 중...
  → [Glob] .claude/commands/alfred/*.md → 8개 (예상: 10개)
  → "❌ 검증 실패: 2개 파일 누락"
```

**복구 절차**:
```text
[Step 1] 누락 파일 파악
  → 템플릿과 실제 파일 목록 비교
  → 누락된 파일: [3-sync.md, 8-project.md]

[Step 2] 사용자에게 선택 제안
  → "Phase 4 재실행" → 전체 복사 다시 시도
  → "백업 복원" → moai restore .moai-backup/{timestamp}
  → "무시하고 진행" → 불완전한 상태로 완료 (위험)

[Step 3] "Phase 4 재실행" 선택 시
  → Alfred Phase 4 절차 재실행
  → 완료 후 Phase 5 재검증
  → IF 재검증 통과: "✅ 검증 통과 (재시도 성공)"
  → IF 재검증 실패: 시나리오 2 반복 (최대 3회)

[Step 4] "백업 복원" 선택 시
  → [Bash] moai restore .moai-backup/{timestamp}
  → "✅ 복원 완료, 재시도하시겠습니까?"
  → 재시도 선택 시 처음부터 다시 실행
```

---

### 시나리오 3: 버전 불일치

**상황**:
```text
Phase 5 검증 중...
  → [Grep] "version:" .moai/memory/development-guide.md → v0.0.1
  → [Bash] npm list moai-adk → v0.0.2
  → "❌ 버전 불일치 감지"
```

**복구 절차**:
```text
[Step 1] 사용자에게 보고
  → "⚠️ development-guide.md 버전(v0.0.1)과 패키지 버전(v0.0.2)이 불일치합니다."
  → "이는 템플릿 복사가 제대로 되지 않았음을 의미합니다."

[Step 2] 원인 분석 안내
  → 가능한 원인:
    a. npm 캐시 손상
    b. 템플릿 디렉토리 경로 오류
    c. 파일 복사 중 네트워크 오류

[Step 3] 선택 제안
  → "Phase 3 재실행" → npm 재설치 (npm cache clean + install)
  → "Phase 4 재실행" → 템플릿 재복사
  → "무시" → 버전 불일치 상태로 완료 (권장하지 않음)

[Step 4] 자동 복구 시도 (Phase 3 선택 시)
  → [Bash] npm cache clean --force
  → [Bash] npm install moai-adk@latest
  → Phase 4 재실행
  → Phase 5 재검증
```

---

### 시나리오 4: Write 도구 실패 (디렉토리 없음)

**상황**:
```text
[Write] .claude/commands/alfred/1-spec.md → ❌ (디렉토리 없음)
```

**자동 복구**:
```text
[Step 1] 오류 감지
  → "❌ Write 실패: .claude/commands/alfred/ 디렉토리 없음"

[Step 2] 디렉토리 자동 생성
  → [Bash] mkdir -p .claude/commands/alfred
  → "✅ 디렉토리 생성 완료"

[Step 3] Write 재시도
  → [Write] .claude/commands/alfred/1-spec.md
  → "✅ 파일 복사 성공 (재시도)"
```

**재시도 실패 시**:
- 디스크 공간 확인 안내
- 권한 문제 확인 안내
- 시나리오 1로 진행 (파일 복사 실패)

## 관련 명령어

- `/alfred:8-project` - 프로젝트 초기화/재설정
- `moai restore` - 백업 복원
- `moai doctor` - 시스템 진단
- `moai status` - 현재 상태 확인

## 버전 호환성

**MoAI-ADK Semantic Versioning** (`v0.x.y` 기준):

- **v0.2.x → v0.2.y**: 패치 업데이트 (완전 호환, 버그 수정/문서 개선)
- **v0.2.x → v0.3.x**: 마이너 업데이트 (신규 기능 추가, 설정 확인 권장)
- **v0.x.x → v1.x.x**: 메이저 업데이트 (Breaking Changes, 마이그레이션 가이드 필수)

**현재 버전**: v0.2.5
**다음 릴리스**: v0.2.6 (지능형 병합 시스템)
