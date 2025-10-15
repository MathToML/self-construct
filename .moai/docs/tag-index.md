# @TAG Index

**생성일**: 2025-10-15
**프로젝트**: self-construct
**대상 브랜치**: feature/SPEC-RECEIPT-002

---

## RECEIPT-001: 영수증 업로드/조회 기능

### @SPEC:RECEIPT-001
- **파일**: `.moai/specs/SPEC-RECEIPT-001/spec.md`
- **버전**: v0.1.0
- **상태**: completed
- **우선순위**: high
- **카테고리**: feature
- **작성일**: 2025-10-14
- **완료일**: 2025-10-15

### @TEST:RECEIPT-001 (6개)

#### Models
- `test/models/receipt_record_test.dart`
  - ReceiptRecord 생성 및 직렬화 테스트
  - Firestore Snapshot 변환 테스트

#### Services
- `test/services/auth_service_test.dart`
  - Firebase Auth 로그인/로그아웃 테스트
  - 인증 상태 관리 테스트

- `test/services/firestore_service_test.dart`
  - Firestore CRUD 작업 테스트
  - 실시간 스트림 조회 테스트

- `test/services/storage_service_test.dart`
  - Firebase Storage 업로드/다운로드 테스트
  - 파일 검증 (크기, 형식) 테스트

#### Pages
- `test/pages/receipt_upload_page_test.dart`
  - 영수증 업로드 UI 테스트
  - 폼 검증 및 제출 플로우 테스트

- `test/pages/receipt_list_page_test.dart`
  - 영수증 목록 렌더링 테스트
  - 실시간 업데이트 테스트

### @CODE:RECEIPT-001 (8개)

#### Models
- `lib/models/receipt_record.dart`
  - FlutterFlow 스타일 Record/Snapshot 패턴 구현
  - ReceiptRecord 클래스 정의

#### Services
- `lib/services/auth_service.dart`
  - Firebase Auth 서비스 구현
  - 로그인/로그아웃 로직

- `lib/services/firestore_service.dart`
  - Firestore CRUD 서비스
  - 실시간 스트림 제공

- `lib/services/storage_service.dart`
  - Firebase Storage 업로드 서비스
  - 파일 검증 및 진행률 추적

#### Pages
- `lib/pages/receipt_upload_page.dart`
  - 영수증 업로드 페이지
  - shadcn_flutter UI 컴포넌트 활용

- `lib/pages/receipt_list_page.dart`
  - 영수증 목록 페이지
  - StreamBuilder 기반 실시간 조회

#### Security
- `firestore.rules`
  - Firestore 보안 규칙
  - 사용자별 접근 제어

- `storage.rules`
  - Firebase Storage 보안 규칙
  - 파일 크기 및 형식 검증

---

## RECEIPT-002: 영수증 실시간 목록 조회 및 상세 업로드 (shadcn_ui)

### @SPEC:RECEIPT-002
- **파일**: `.moai/specs/SPEC-RECEIPT-002/spec.md`
- **버전**: v0.1.0
- **상태**: completed
- **우선순위**: high
- **카테고리**: feature
- **작성일**: 2025-10-15
- **완료일**: 2025-10-15
- **의존성**: RECEIPT-001

### @TEST:RECEIPT-002 (3개)

#### Pages
- `test/pages/receipt_list_page_test.dart`
  - 영수증 목록 페이지 위젯 테스트 (StreamBuilder, ShadButton)
  - 로딩/에러/빈 목록 상태 테스트
  - 실시간 업데이트 시뮬레이션

- `test/pages/receipt_upload_page_test.dart`
  - 영수증 업로드 페이지 위젯 테스트 (ShadInput, ShadSelect)
  - 폼 검증 (필수 필드, 파일 크기, 형식)
  - FilePicker 통합 테스트

#### Widgets
- `test/widgets/receipt_card_test.dart`
  - ReceiptCard 위젯 렌더링 테스트 (ShadCard)
  - 데이터 표시 형식 검증 (금액, 날짜, 카테고리)

### @CODE:RECEIPT-002:UI (3개)

#### Widgets
- `lib/widgets/receipt_card.dart`
  - shadcn_ui ShadCard 기반 영수증 카드 위젯
  - 이미지 썸네일, 가게명, 금액, 날짜 표시
  - 카테고리 Chip 표시

#### Pages
- `lib/pages/receipt_list_page.dart`
  - StreamBuilder + ShadButton 실시간 목록 조회
  - userId 필터링, date 내림차순 정렬
  - 로딩/에러/빈 목록 상태 처리

- `lib/pages/receipt_upload_page.dart`
  - ShadInput + ShadSelect + FilePicker 업로드
  - 필수 필드: amount, category
  - 선택 필드: businessPurpose
  - 파일 크기/형식 검증 (5MB, JPG/PNG)

---

## TAG 체인 검증 결과

### RECEIPT-001 추적성 매트릭스

```
@SPEC:RECEIPT-001 (1개)
    ↓
@TEST:RECEIPT-001 (6개)
    ↓
@CODE:RECEIPT-001 (8개)
```

✅ **SPEC → TEST 링크**: 정상 (6개 테스트 파일에서 SPEC 참조)
✅ **TEST → CODE 링크**: 정상 (각 테스트가 대응하는 구현 코드 참조)
✅ **고아 TAG**: 없음
✅ **중복 TAG**: 없음

### RECEIPT-002 추적성 매트릭스

```
@SPEC:RECEIPT-002 (1개)
    ↓
@TEST:RECEIPT-002 (3개)
    ↓
@CODE:RECEIPT-002:UI (3개)
```

✅ **SPEC → TEST 링크**: 정상 (3개 테스트 파일에서 SPEC 참조)
✅ **TEST → CODE 링크**: 정상 (각 테스트가 대응하는 구현 코드 참조)
✅ **고아 TAG**: 없음
✅ **중복 TAG**: 없음

### 전체 TAG 분포

| TAG 유형 | RECEIPT-001 | RECEIPT-002 | 총계 |
|---------|------------|------------|------|
| @SPEC   | 1          | 1          | 2    |
| @TEST   | 6          | 3          | 9    |
| @CODE   | 8          | 3          | 11   |
| **총계** | **15**    | **7**      | **22** |

---

## 참조 관계 다이어그램

### RECEIPT-001 (Flutter/Firebase 기반 영수증 기능)
```
SPEC-RECEIPT-001.md
    ├── TEST: receipt_record_test.dart ──→ CODE: receipt_record.dart
    ├── TEST: auth_service_test.dart ────→ CODE: auth_service.dart
    ├── TEST: firestore_service_test.dart → CODE: firestore_service.dart
    ├── TEST: storage_service_test.dart ─→ CODE: storage_service.dart
    ├── TEST: receipt_upload_page_test.dart → CODE: receipt_upload_page.dart
    ├── TEST: receipt_list_page_test.dart ──→ CODE: receipt_list_page.dart
    ├── (SPEC 참조) ──────────────────────→ CODE: firestore.rules
    └── (SPEC 참조) ──────────────────────→ CODE: storage.rules
```

### RECEIPT-002 (shadcn_ui 기반 UI 레이어)
```
SPEC-RECEIPT-002.md (depends_on: RECEIPT-001)
    ├── TEST: receipt_card_test.dart ────→ CODE: receipt_card.dart
    ├── TEST: receipt_list_page_test.dart → CODE: receipt_list_page.dart
    └── TEST: receipt_upload_page_test.dart → CODE: receipt_upload_page.dart
```

---

## 의존성 그래프

```
RECEIPT-001 (v0.1.0)
    └── RECEIPT-002 (v0.1.0) ← depends_on: RECEIPT-001
```

**의존성 설명**:
- RECEIPT-002는 RECEIPT-001의 모델(ReceiptRecord), 서비스(AuthService, FirestoreService, StorageService)를 재사용
- RECEIPT-002는 UI 레이어만 구현 (shadcn_ui 기반)

---

**다음 갱신**: SPEC-RECEIPT-003 구현 시 자동 업데이트
**유지관리**: `/alfred:3-sync` 명령으로 자동 동기화
