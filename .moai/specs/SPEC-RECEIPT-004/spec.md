---
id: RECEIPT-004
version: 0.1.0
status: completed
created: 2025-10-18
updated: 2025-10-18
author: @edward
priority: medium
category: feature
labels:
  - flutter
  - firebase
  - search
  - filter
  - firestore-query
depends_on:
  - RECEIPT-001
  - RECEIPT-002
scope:
  packages:
    - lib/pages/receipts
    - lib/services
    - lib/widgets
  files:
    - receipt_search_page.dart
    - receipt_filter_widget.dart
    - firestore_service.dart
---

# @SPEC:RECEIPT-004: 영수증 검색 및 필터링

## HISTORY

### v0.1.0 (2025-10-18)
- **COMPLETED**: TDD 구현 완료 (RED-GREEN-REFACTOR)
- **AUTHOR**: @edward
- **FEATURES**:
  - 키워드 검색 (300ms debounce, businessPurpose 필드)
  - 카테고리 필터 (식비/교통/숙박/기타 단일 선택)
  - 날짜 범위 필터 (DatePicker 기반)
  - 금액 범위 필터 (최소~최대 입력)
  - 제출 상태 필터 (제출됨/대기중 토글)
  - 필터 초기화 버튼
  - 활성 필터 배지 표시
- **TESTS**: 20개 테스트 통과 (모두 pass)
  - `test/utils/receipt_filter_test.dart` (16개)
  - `test/utils/debounce_test.dart` (4개)
- **CODE**: 7개 파일 생성/수정
  - `lib/utils/debounce.dart` (25 LOC)
  - `lib/utils/receipt_filter.dart` (95 LOC)
  - `lib/pages/receipts/receipt_search_page.dart` (231 LOC)
  - `lib/widgets/receipt_filter_widget.dart` (207 LOC)
  - `lib/services/firestore_service.dart` (+25 LOC)
  - `lib/main.dart` (+5 LOC)
  - `pubspec.yaml` (intl: ^0.20.2 추가)
- **COMMITS**:
  - RED: 7ec867c - 테스트 케이스 작성 (20개)
  - GREEN: fd65fbc - 구현 완료 (7개 파일)
- **TECH STACK**: Flutter 3.24+, shadcn_flutter, Firestore, Dart Timer

### v0.0.1 (2025-10-18)
- **INITIAL**: 영수증 검색 및 필터링 기능 SPEC 최초 작성
- **AUTHOR**: @edward
- **SCOPE**: 키워드 검색, 카테고리/날짜/금액/상태 필터링 기능
- **TECH STACK**: Flutter 3.24+, shadcn_flutter, Cloud Firestore compound queries, RxDart/Timer (debounce)
- **TARGET**: 사용자가 영수증을 효율적으로 검색하고 필터링할 수 있는 기능 제공

---

## 1. Environment (환경 및 전제조건)

### 기술 환경
- **Frontend**: Flutter Web 3.24+
- **UI Framework**: shadcn_flutter (ShadInput, ShadSelect, ShadBadge, ShadButton)
- **Backend**: Cloud Firestore (compound queries)
- **Debounce**: RxDart `debounceTime` 또는 Dart `Timer` 패턴
- **Dependencies**:
  - `cloud_firestore: ^4.0.0`
  - `rxdart: ^0.27.0` (선택적 - debounce용)

### Firestore 데이터 구조 (기존)
```
receipts/
  └── {receiptId}
      ├── userId: string
      ├── imageUrl: string
      ├── amount: number
      ├── receiptDate: timestamp  # 영수증 발행 날짜
      ├── category: string        # "식비", "교통", "숙박", "기타"
      ├── businessPurpose: string # 검색 대상 필드
      ├── createdAt: timestamp
      └── isSubmitted: boolean    # "제출됨" / "대기중"
```

### Firestore 복합 인덱스 요구사항
복합 필터링을 위해 다음 인덱스가 필요:
```
Collection: receipts
Fields:
  - userId (Ascending)
  - category (Ascending)
  - receiptDate (Descending)
  - createdAt (Descending)
```

**인덱스 생성 방법**:
1. Firebase Console → Firestore Database → Indexes
2. 자동 인덱스 제안 수락 (첫 쿼리 실행 시 에러 메시지에서 제공)

---

## 2. Assumptions (전제 조건)

### 데이터 가정
- 모든 영수증은 `userId` 필드를 가지고 있음 (사용자별 필터링 기본)
- `category` 필드는 고정된 4개 값 중 하나: "식비", "교통", "숙박", "기타"
- `businessPurpose` 필드는 검색 가능한 텍스트 필드 (부분 일치 검색 불가 → full-text search 대안 필요)
- `receiptDate`는 영수증 발행 날짜, `createdAt`은 문서 생성 날짜

### 검색 제약
- Firestore는 **부분 일치 검색(LIKE)을 지원하지 않음**
- **대안 1**: 클라이언트 측 필터링 (전체 데이터 로드 후 검색)
- **대안 2**: Algolia/Elasticsearch 통합 (추후 확장)
- **현재 구현**: 클라이언트 측 필터링 (영수증 수가 적을 때 적합)

### 성능 가정
- 사용자당 영수증 수: 평균 100개 이하 (클라이언트 필터링 가능)
- 검색 debounce: 300ms (사용자 타이핑 완료 후 검색)
- 쿼리 결과 제한: 최대 100개 (limit 100)

---

## 3. Requirements (기능 요구사항 - EARS 방식)

### 3.1. Ubiquitous Requirements (기본 요구사항)
- 시스템은 영수증 검색 및 필터링 기능을 제공해야 한다
- 시스템은 키워드 검색 입력 필드를 제공해야 한다
- 시스템은 카테고리, 날짜 범위, 금액 범위, 제출 상태 필터를 제공해야 한다
- 시스템은 활성화된 필터를 배지로 표시해야 한다
- 시스템은 필터 초기화 버튼을 제공해야 한다

### 3.2. Event-driven Requirements (이벤트 기반)
- WHEN 사용자가 검색 키워드를 입력하면, 시스템은 300ms debounce 후 검색을 수행해야 한다
- WHEN 사용자가 필터 조건을 변경하면, 시스템은 즉시 결과를 업데이트해야 한다
- WHEN 사용자가 "초기화" 버튼을 클릭하면, 시스템은 모든 필터를 제거하고 전체 목록을 표시해야 한다
- WHEN 복합 필터가 적용되면, 시스템은 Firestore 복합 쿼리를 실행해야 한다
- WHEN 검색 결과가 없으면, 시스템은 "결과 없음" 메시지를 표시해야 한다

### 3.3. State-driven Requirements (상태 기반)
- WHILE 검색 결과가 로딩 중일 때, 시스템은 로딩 인디케이터를 표시해야 한다
- WHILE 필터가 적용된 상태일 때, 시스템은 활성 필터 개수를 표시해야 한다
- WHILE 키워드 검색 중일 때, 시스템은 debounce 타이머를 실행해야 한다

### 3.4. Optional Features (선택적 기능)
- WHERE 검색 결과가 없으면, 시스템은 "결과 없음" 안내 메시지를 표시할 수 있다
- WHERE 필터 조합이 복잡하면, 시스템은 "고급 검색" 모드를 제공할 수 있다 (Phase 2)

### 3.5. Constraints (제약사항)
- IF 복합 필터가 적용되면, 시스템은 Firestore 복합 인덱스를 요구해야 한다
- 검색 결과는 100개 이하로 제한되어야 한다
- 키워드 검색은 클라이언트 측 필터링으로 구현되어야 한다 (Firestore full-text search 미지원)
- 날짜 범위는 시작일 ≤ 종료일 조건을 만족해야 한다
- 금액 범위는 최소 금액 ≤ 최대 금액 조건을 만족해야 한다

---

## 4. Specifications (상세 명세)

### 4.1. UI 컴포넌트 구조

```dart
// 검색 및 필터 페이지
ReceiptSearchPage
  ├── ShadInput (키워드 검색, debounce)
  ├── FilterSection
  │   ├── ShadSelect (카테고리 필터)
  │   ├── DateRangePicker (날짜 범위)
  │   ├── AmountRangeInput (금액 범위)
  │   └── ShadButton (상태 필터 토글)
  ├── ActiveFiltersRow (활성 필터 배지)
  ├── ShadButton ("초기화" 버튼)
  └── ReceiptListView (검색 결과)
```

### 4.2. 검색 로직 플로우

**키워드 검색 (debounce)**:
```dart
import 'dart:async';

class ReceiptSearchPage extends StatefulWidget {
  @override
  _ReceiptSearchPageState createState() => _ReceiptSearchPageState();
}

class _ReceiptSearchPageState extends State<ReceiptSearchPage> {
  Timer? _debounceTimer;
  String _searchKeyword = '';

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      setState(() {
        _searchKeyword = value.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
```

**Firestore 복합 쿼리**:
```dart
Query<Map<String, dynamic>> _buildQuery() {
  Query<Map<String, dynamic>> query = FirebaseFirestore.instance
      .collection('receipts')
      .where('userId', isEqualTo: currentUserId);

  // 카테고리 필터
  if (_selectedCategory != null) {
    query = query.where('category', isEqualTo: _selectedCategory);
  }

  // 날짜 범위 필터
  if (_startDate != null) {
    query = query.where('receiptDate', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
  }
  if (_endDate != null) {
    query = query.where('receiptDate', isLessThanOrEqualTo: Timestamp.fromDate(_endDate!));
  }

  // 제출 상태 필터
  if (_isSubmittedFilter != null) {
    query = query.where('isSubmitted', isEqualTo: _isSubmittedFilter);
  }

  return query.orderBy('receiptDate', descending: true).limit(100);
}
```

**클라이언트 측 필터링 (키워드 + 금액)**:
```dart
List<ReceiptRecord> _applyClientFilters(List<ReceiptRecord> receipts) {
  return receipts.where((receipt) {
    // 키워드 검색 (businessPurpose)
    if (_searchKeyword.isNotEmpty) {
      if (!(receipt.businessPurpose?.toLowerCase().contains(_searchKeyword) ?? false)) {
        return false;
      }
    }

    // 금액 범위 필터
    if (_minAmount != null && receipt.amount < _minAmount!) return false;
    if (_maxAmount != null && receipt.amount > _maxAmount!) return false;

    return true;
  }).toList();
}
```

### 4.3. 필터 UI 상세 설계

**카테고리 필터 (ShadSelect)**:
```dart
ShadSelect<String>(
  placeholder: '카테고리 선택',
  options: [
    ShadOption(value: '식비', child: Text('식비')),
    ShadOption(value: '교통', child: Text('교통')),
    ShadOption(value: '숙박', child: Text('숙박')),
    ShadOption(value: '기타', child: Text('기타')),
  ],
  selectedOptionBuilder: (context, value) => Text(value),
  onChanged: (value) {
    setState(() {
      _selectedCategory = value;
    });
  },
)
```

**날짜 범위 필터**:
```dart
Row(
  children: [
    Expanded(
      child: ShadButton(
        child: Text(_startDate == null ? '시작일' : DateFormat('yyyy-MM-dd').format(_startDate!)),
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _startDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            setState(() => _startDate = date);
          }
        },
      ),
    ),
    SizedBox(width: 8),
    Text('~'),
    SizedBox(width: 8),
    Expanded(
      child: ShadButton(
        child: Text(_endDate == null ? '종료일' : DateFormat('yyyy-MM-dd').format(_endDate!)),
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _endDate ?? DateTime.now(),
            firstDate: _startDate ?? DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            setState(() => _endDate = date);
          }
        },
      ),
    ),
  ],
)
```

**금액 범위 필터**:
```dart
Row(
  children: [
    Expanded(
      child: ShadInput(
        placeholder: '최소 금액',
        keyboardType: TextInputType.number,
        onChanged: (value) {
          setState(() {
            _minAmount = double.tryParse(value);
          });
        },
      ),
    ),
    SizedBox(width: 8),
    Text('~'),
    SizedBox(width: 8),
    Expanded(
      child: ShadInput(
        placeholder: '최대 금액',
        keyboardType: TextInputType.number,
        onChanged: (value) {
          setState(() {
            _maxAmount = double.tryParse(value);
          });
        },
      ),
    ),
  ],
)
```

**상태 필터 (토글)**:
```dart
Row(
  children: [
    ShadButton(
      variant: _isSubmittedFilter == true ? ShadButtonVariant.primary : ShadButtonVariant.outline,
      child: Text('제출됨'),
      onPressed: () {
        setState(() {
          _isSubmittedFilter = _isSubmittedFilter == true ? null : true;
        });
      },
    ),
    SizedBox(width: 8),
    ShadButton(
      variant: _isSubmittedFilter == false ? ShadButtonVariant.primary : ShadButtonVariant.outline,
      child: Text('대기중'),
      onPressed: () {
        setState(() {
          _isSubmittedFilter = _isSubmittedFilter == false ? null : false;
        });
      },
    ),
  ],
)
```

**활성 필터 배지**:
```dart
Wrap(
  spacing: 8,
  children: [
    if (_selectedCategory != null)
      ShadBadge(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('카테고리: $_selectedCategory'),
            SizedBox(width: 4),
            GestureDetector(
              onTap: () => setState(() => _selectedCategory = null),
              child: Icon(Icons.close, size: 16),
            ),
          ],
        ),
      ),
    if (_startDate != null || _endDate != null)
      ShadBadge(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('날짜: ${_startDate != null ? DateFormat('MM/dd').format(_startDate!) : '시작'} ~ ${_endDate != null ? DateFormat('MM/dd').format(_endDate!) : '종료'}'),
            SizedBox(width: 4),
            GestureDetector(
              onTap: () => setState(() {
                _startDate = null;
                _endDate = null;
              }),
              child: Icon(Icons.close, size: 16),
            ),
          ],
        ),
      ),
    // 금액, 상태 필터 배지도 유사하게 추가
  ],
)
```

### 4.4. Firestore 복합 인덱스 생성

**Firebase Console에서 수동 생성**:
1. Firebase Console → Firestore Database → Indexes
2. "Create Index" 클릭
3. 다음 필드 추가:
   - Collection ID: `receipts`
   - Fields:
     - `userId` (Ascending)
     - `category` (Ascending)
     - `receiptDate` (Descending)
   - Query scope: Collection

**자동 생성 (추천)**:
첫 복합 쿼리 실행 시 Firestore 에러 메시지에서 제공하는 인덱스 생성 링크 클릭:
```
Error: The query requires an index. You can create it here:
https://console.firebase.google.com/project/.../firestore/indexes?create_composite=...
```

### 4.5. 성능 최적화 전략

**1. Debounce 패턴**:
- 키워드 입력 시 300ms 대기 후 검색 실행
- 불필요한 쿼리 방지 및 네트워크 요청 감소

**2. 쿼리 결과 제한**:
- `.limit(100)` 적용하여 과도한 데이터 로드 방지
- 페이지네이션 고려 (Phase 2)

**3. 클라이언트 캐싱**:
- Firestore는 자동으로 캐시 제공 (Offline Persistence)
- 동일 쿼리 재실행 시 캐시 데이터 사용

**4. 인덱스 최적화**:
- 자주 사용하는 필터 조합에 대한 복합 인덱스 생성
- Firebase Console에서 인덱스 성능 모니터링

---

## 5. Traceability (@TAG 추적성)

### TAG 체인
```
@SPEC:RECEIPT-004
  ↓
@TEST:RECEIPT-004
  - tests/receipts/receipt_search_test.dart
  - tests/services/firestore_query_test.dart
  - tests/widgets/filter_widget_test.dart
  ↓
@CODE:RECEIPT-004
  - lib/pages/receipts/receipt_search_page.dart
  - lib/widgets/receipt_filter_widget.dart
  - lib/services/firestore_service.dart (확장)
  ↓
@DOC:RECEIPT-004
  - docs/user-guide/receipt-search.md
  - docs/architecture/firestore-queries.md
```

### 의존성
- **RECEIPT-001**: `ReceiptRecord` 모델, `FirestoreService` 기본 구조
- **RECEIPT-002**: 영수증 목록 조회 기능 (검색 결과 표시)

---

## 6. Non-Functional Requirements (비기능 요구사항)

### 성능
- 검색 결과 반환 시간: 500ms 이내 (100개 문서 기준)
- Debounce 지연 시간: 300ms
- UI 응답성: 필터 변경 시 즉시 반영 (0ms)

### 사용성
- 검색 입력 필드는 페이지 상단에 고정
- 활성 필터는 시각적으로 구분 (배지 표시)
- "초기화" 버튼은 항상 접근 가능

### 확장성
- Phase 2: Algolia/Elasticsearch 통합 준비
- Phase 2: 페이지네이션 및 무한 스크롤
- Phase 2: 저장된 검색 필터 (즐겨찾기)

---

## 7. 구현 우선순위

### Phase 1: 기본 검색 및 필터링 (이번 SPEC 범위)
1. 키워드 검색 (debounce 패턴)
2. 카테고리 필터 (단일 선택)
3. 날짜 범위 필터
4. 금액 범위 필터
5. 상태 필터 (제출됨/대기중)
6. 필터 초기화 버튼

### Phase 2: 고급 기능 (추후 확장)
- Full-text search (Algolia 연동)
- 다중 카테고리 선택
- 저장된 필터 프리셋
- 검색 히스토리

---

## 8. 참고 자료

### Firestore 쿼리
- [Firestore Compound Queries](https://firebase.google.com/docs/firestore/query-data/queries)
- [Firestore Index Best Practices](https://firebase.google.com/docs/firestore/query-data/indexing)

### Debounce 패턴
- [Dart Timer API](https://api.dart.dev/stable/dart-async/Timer-class.html)
- [RxDart debounceTime](https://pub.dev/packages/rxdart)

### shadcn_flutter
- [ShadInput Component](https://flutter-shadcn-ui.mariuti.com/)
- [ShadSelect Component](https://flutter-shadcn-ui.mariuti.com/)

---

**다음 단계**: `/alfred:2-build SPEC-RECEIPT-004` 실행하여 TDD 구현 시작
