# SPEC-RECEIPT-003 구현 계획서

## TDD 구현 순서

### Phase 1: RED (테스트 작성)

#### 1.1 ReceiptDetailPage Widget Tests
- **파일**: `test/pages/receipt_detail_page_test.dart`
- **테스트 케이스**:
  1. 페이지가 정상 렌더링되는지 확인
  2. 모든 정보가 화면에 표시되는지 확인 (금액, 날짜, 카테고리, 업무 목적, 상태)
  3. 제출 전 영수증: 수정/삭제/제출 버튼이 표시되는지 확인
  4. 제출 후 영수증: 버튼이 비활성화되고 안내 메시지가 표시되는지 확인
  5. 이미지가 정상 로드되는지 확인
  6. 삭제 버튼 클릭 시 확인 다이얼로그가 표시되는지 확인
  7. 제출 버튼 클릭 시 확인 다이얼로그가 표시되는지 확인

#### 1.2 CRUD Operations Tests
- **파일**: `test/services/receipt_service_test.dart` (확장)
- **테스트 케이스**:
  1. `updateReceipt()` - Firestore 업데이트 성공
  2. `deleteReceipt()` - Firestore + Storage 삭제 성공
  3. `submitReceipt()` - isSubmitted 업데이트 성공
  4. 제출된 영수증 수정 시 예외 발생
  5. 제출된 영수증 삭제 시 예외 발생

#### 1.3 Integration Tests (선택)
- **파일**: `test/integration/receipt_detail_flow_test.dart`
- **테스트 시나리오**:
  1. 목록 화면 → 카드 탭 → 상세 화면 이동
  2. 상세 화면 → 수정 버튼 → 수정 화면 → 저장 → 상세 화면 복귀
  3. 상세 화면 → 삭제 버튼 → 확인 → 목록 화면 복귀
  4. 상세 화면 → 제출 버튼 → 확인 → 버튼 비활성화

### Phase 2: GREEN (최소 구현)

#### 2.1 ReceiptDetailPage 기본 구조
- **파일**: `lib/pages/receipt_detail_page.dart`
- **구현 내용**:
  ```dart
  class ReceiptDetailPage extends StatefulWidget {
    final String receiptId;
    // ...
  }

  class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
    ReceiptRecord? _receipt;
    bool _isLoading = true;
    bool _isDeleting = false;
    bool _isSubmitting = false;

    @override
    void initState() {
      super.initState();
      _loadReceipt();
    }

    Future<void> _loadReceipt() async {
      // Firestore에서 영수증 로드
    }

    @override
    Widget build(BuildContext context) {
      // UI 렌더링
    }
  }
  ```

#### 2.2 이미지 표시
- **구현**:
  - `CachedNetworkImage` 사용
  - 전체 크기 이미지 표시
  - 로딩/에러 상태 처리

#### 2.3 정보 표시
- **구현**:
  - 금액: `NumberFormat.currency(locale: 'ko_KR', symbol: '₩')`
  - 날짜: `DateFormat('yyyy-MM-dd')`
  - 카테고리: `ShadBadge`
  - 제출 상태: 조건부 배지 표시

#### 2.4 수정 기능
- **구현**:
  - `ReceiptUploadPage` 재사용
  - `receiptId` 파라미터로 수정 모드 판별
  - 기존 데이터 로드 및 컨트롤러 초기화
  - Firestore 업데이트 로직

#### 2.5 삭제 기능
- **구현**:
  - `_showDeleteDialog()` 확인 다이얼로그
  - `_deleteReceipt()` 삭제 로직
    1. Storage 이미지 삭제
    2. Firestore 문서 삭제
    3. 목록 화면으로 복귀

#### 2.6 제출 기능
- **구현**:
  - `_showSubmitDialog()` 확인 다이얼로그
  - `_submitReceipt()` 제출 로직
    1. `isSubmitted: true` 업데이트
    2. 로컬 상태 업데이트
    3. 버튼 상태 갱신

### Phase 3: REFACTOR (리팩토링)

#### 3.1 코드 품질 개선
- **작업**:
  1. 중복 코드 제거 (다이얼로그 로직)
  2. 에러 처리 강화
  3. 로딩 상태 일관성 유지
  4. 주석 및 문서화

#### 3.2 UI/UX 개선
- **작업**:
  1. 로딩 애니메이션 추가
  2. 에러 메시지 개선
  3. 확인 다이얼로그 디자인 통일
  4. 접근성 레이블 추가

#### 3.3 성능 최적화
- **작업**:
  1. 이미지 캐싱 최적화
  2. Firestore 쿼리 최소화
  3. 불필요한 리렌더링 방지

### Phase 4: STYLE (shadcn_ui 적용)

#### 4.1 컴포넌트 통일
- **작업**:
  1. 모든 버튼 → `ShadButton`
  2. 다이얼로그 → `ShadDialog`
  3. 카드 → `ShadCard`
  4. 토스트 → `ShadToast`

#### 4.2 디자인 일관성
- **작업**:
  1. 색상 테마 통일
  2. 패딩/마진 일관성
  3. 폰트 크기 표준화

---

## 파일 구조

```
lib/
├── pages/
│   ├── receipt_detail_page.dart          # @CODE:RECEIPT-003:UI (NEW)
│   ├── receipt_upload_page.dart          # @CODE:RECEIPT-003:UI (MODIFIED)
│   └── receipt_list_page.dart            # (EXISTING)
│
├── widgets/
│   └── receipt_card.dart                 # @CODE:RECEIPT-003:UI (MODIFIED)
│
└── services/
    └── receipt_service.dart              # (EXISTING, 확장 가능)

test/
├── pages/
│   ├── receipt_detail_page_test.dart     # @TEST:RECEIPT-003 (NEW)
│   └── receipt_upload_page_test.dart     # (EXISTING)
│
└── integration/
    └── receipt_detail_flow_test.dart     # @TEST:RECEIPT-003 (NEW, 선택)
```

---

## 의존성 확인

### 기존 코드 재사용
- **RECEIPT-001**:
  - `ReceiptRecord` 모델
  - Firebase 설정

- **RECEIPT-002**:
  - `ReceiptCard` 위젯 (onTap 추가)
  - `ReceiptListPage` (네비게이션 소스)
  - `ReceiptUploadPage` (수정 모드 추가)

### 새로 추가할 패키지 (필요 시)
- `cached_network_image` - 이미지 캐싱 (이미 사용 중)
- `go_router` - 라우팅 (이미 사용 중)
- `intl` - 날짜/통화 형식 (이미 사용 중)

---

## 예상 작업 시간

| 단계 | 작업 내용 | 예상 시간 |
|-----|---------|---------|
| RED | 테스트 작성 | 2시간 |
| GREEN | 최소 구현 | 3시간 |
| REFACTOR | 리팩토링 | 1시간 |
| STYLE | UI 개선 | 1시간 |
| **총계** | | **7시간** |

---

## 리스크 및 대응 방안

### 리스크 1: Firestore 보안 규칙
- **문제**: 제출된 영수증 수정 시 권한 에러
- **대응**: 클라이언트 측에서 `isSubmitted` 체크 후 UI 비활성화
- **검증**: Firestore 규칙 테스트 작성

### 리스크 2: Storage 파일 삭제 실패
- **문제**: 네트워크 오류로 Storage 삭제 실패
- **대응**: 에러 처리 및 재시도 로직 추가
- **검증**: 통합 테스트로 삭제 플로우 검증

### 리스크 3: 수정 모드 충돌
- **문제**: ReceiptUploadPage 재사용 시 상태 관리 복잡도 증가
- **대응**: 조건부 로직 명확히 분리, 주석 추가
- **검증**: 유닛 테스트로 수정 모드 검증

---

## 체크리스트

### RED 단계
- [ ] ReceiptDetailPage 위젯 테스트 작성
- [ ] CRUD operations 테스트 작성
- [ ] 통합 테스트 작성 (선택)

### GREEN 단계
- [ ] ReceiptDetailPage 기본 구조 구현
- [ ] 이미지 및 정보 표시 구현
- [ ] 수정 기능 구현
- [ ] 삭제 기능 구현
- [ ] 제출 기능 구현

### REFACTOR 단계
- [ ] 코드 품질 개선
- [ ] UI/UX 개선
- [ ] 성능 최적화

### STYLE 단계
- [ ] shadcn_ui 컴포넌트 적용
- [ ] 디자인 일관성 확보

### 최종 검증
- [ ] 모든 테스트 통과
- [ ] `dart analyze` 경고 없음
- [ ] `flutter test` 성공
- [ ] 실제 브라우저에서 동작 확인

---

**다음 단계**: `/alfred:2-build SPEC-RECEIPT-003` 실행하여 이 계획대로 TDD 구현 시작
