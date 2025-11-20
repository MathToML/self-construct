# SPEC-RECEIPT-004 구현 계획

> **영수증 검색 및 필터링 기능 TDD 구현 계획**
>
> SPEC ID: RECEIPT-004
> Version: 0.0.1
> Status: draft

---

## 1. 구현 전략

### TDD 접근 방식
본 SPEC은 **RED-GREEN-REFACTOR** 사이클을 엄격히 따르며, SPEC-First TDD 방법론을 적용합니다.

1. **RED Phase**: 실패하는 테스트 작성
   - 키워드 검색 테스트
   - 카테고리 필터 테스트
   - 날짜 범위 필터 테스트
   - 금액 범위 필터 테스트
   - 상태 필터 테스트
   - 필터 초기화 테스트

2. **GREEN Phase**: 테스트를 통과하는 최소한의 코드 작성
   - Firestore 복합 쿼리 구현
   - Debounce 패턴 적용
   - 클라이언트 측 필터링 로직
   - UI 컴포넌트 구현

3. **REFACTOR Phase**: 코드 품질 개선
   - 필터 로직 모듈화
   - 재사용 가능한 위젯 분리
   - 성능 최적화

---

## 2. 우선순위별 작업 항목

### 1차 목표: 핵심 검색 기능

#### 1.1. Debounce 패턴 구현
- **목표**: 키워드 입력 시 300ms debounce 적용
- **테스트**:
  - 키워드 입력 후 300ms 이내 재입력 시 타이머 리셋
  - 300ms 대기 후 검색 실행 확인
- **구현**:
  - `Timer` 또는 `RxDart.debounceTime` 사용
  - `dispose()` 시 타이머 정리

#### 1.2. 클라이언트 측 키워드 검색
- **목표**: `businessPurpose` 필드에서 키워드 검색
- **테스트**:
  - "회의" 키워드로 검색 시 해당 영수증만 반환
  - 대소문자 구분 없이 검색
  - 빈 키워드 시 전체 목록 반환
- **구현**:
  - `String.toLowerCase()` 사용
  - `contains()` 메서드로 부분 일치 검색

### 2차 목표: Firestore 복합 필터

#### 2.1. 카테고리 필터
- **목표**: 선택한 카테고리의 영수증만 조회
- **테스트**:
  - "식비" 선택 시 해당 카테고리만 반환
  - null 선택 시 전체 카테고리 반환
- **구현**:
  - `where('category', isEqualTo: _selectedCategory)`
  - `ShadSelect` 컴포넌트 연동

#### 2.2. 날짜 범위 필터
- **목표**: 시작일~종료일 범위 내 영수증 조회
- **테스트**:
  - 2025-10-01 ~ 2025-10-31 범위 검색
  - 시작일만 지정 시 해당 날짜 이후 조회
  - 종료일만 지정 시 해당 날짜 이전 조회
  - 잘못된 범위 (시작일 > 종료일) 방지
- **구현**:
  - `where('receiptDate', isGreaterThanOrEqualTo: ...)`
  - `where('receiptDate', isLessThanOrEqualTo: ...)`
  - Date picker UI 통합

#### 2.3. 금액 범위 필터 (클라이언트)
- **목표**: 최소~최대 금액 범위 내 영수증 조회
- **테스트**:
  - 10000원 ~ 50000원 범위 검색
  - 최소 금액만 지정 시 해당 금액 이상 조회
  - 최대 금액만 지정 시 해당 금액 이하 조회
  - 잘못된 범위 (최소 > 최대) 방지
- **구현**:
  - 클라이언트 측 필터링 (`amount >= min && amount <= max`)
  - `ShadInput` 숫자 입력 필드

#### 2.4. 상태 필터
- **목표**: 제출 상태별 영수증 조회
- **테스트**:
  - "제출됨" 선택 시 `isSubmitted: true`만 반환
  - "대기중" 선택 시 `isSubmitted: false`만 반환
  - 선택 해제 시 전체 상태 반환
- **구현**:
  - `where('isSubmitted', isEqualTo: _isSubmittedFilter)`
  - 토글 버튼 UI

### 3차 목표: UI/UX 개선

#### 3.1. 활성 필터 배지
- **목표**: 적용된 필터를 시각적으로 표시
- **테스트**:
  - 필터 적용 시 배지 표시
  - 배지 클릭 시 해당 필터 제거
- **구현**:
  - `ShadBadge` 컴포넌트
  - 동적 배지 생성 (`Wrap` 위젯)

#### 3.2. 필터 초기화
- **목표**: 모든 필터를 한 번에 제거
- **테스트**:
  - "초기화" 버튼 클릭 시 모든 필터 상태 null로 변경
  - 전체 영수증 목록 표시
- **구현**:
  - 모든 필터 상태 변수 초기화
  - `setState()` 호출

#### 3.3. 검색 결과 없음 UI
- **목표**: 검색 결과가 없을 때 안내 메시지 표시
- **테스트**:
  - 검색 결과 0개 시 "결과 없음" 메시지
- **구현**:
  - `ListView.builder` 조건부 렌더링
  - 빈 상태 UI 디자인

---

## 3. 기술적 접근 방법

### 3.1. Debounce 패턴 선택

**옵션 1: Dart Timer (권장)**
```dart
Timer? _debounceTimer;

void _onSearchChanged(String value) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 300), () {
    setState(() {
      _searchKeyword = value;
    });
  });
}

@override
void dispose() {
  _debounceTimer?.cancel();
  super.dispose();
}
```

**장점**:
- 외부 패키지 불필요
- 간단한 구현
- 메모리 누수 방지 용이

**옵션 2: RxDart debounceTime**
```dart
final _searchController = StreamController<String>();

@override
void initState() {
  super.initState();
  _searchController.stream
      .debounceTime(Duration(milliseconds: 300))
      .listen((keyword) {
    setState(() {
      _searchKeyword = keyword;
    });
  });
}
```

**장점**:
- 더 선언적인 코드
- 복잡한 스트림 처리 시 유용

**선택**: **Dart Timer** (간단하고 의존성 적음)

### 3.2. Firestore 쿼리 구조

**단계별 쿼리 빌드**:
```dart
Query<Map<String, dynamic>> _buildQuery() {
  Query<Map<String, dynamic>> query = FirebaseFirestore.instance
      .collection('receipts')
      .where('userId', isEqualTo: currentUserId);

  // 서버 측 필터 (Firestore where)
  if (_selectedCategory != null) {
    query = query.where('category', isEqualTo: _selectedCategory);
  }

  if (_startDate != null) {
    query = query.where('receiptDate', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
  }

  if (_endDate != null) {
    query = query.where('receiptDate', isLessThanOrEqualTo: Timestamp.fromDate(_endDate!));
  }

  if (_isSubmittedFilter != null) {
    query = query.where('isSubmitted', isEqualTo: _isSubmittedFilter);
  }

  return query.orderBy('receiptDate', descending: true).limit(100);
}
```

**클라이언트 측 필터 (Firestore 이후)**:
```dart
List<ReceiptRecord> _applyClientFilters(List<ReceiptRecord> receipts) {
  return receipts.where((receipt) {
    // 키워드 검색
    if (_searchKeyword.isNotEmpty) {
      if (!(receipt.businessPurpose?.toLowerCase().contains(_searchKeyword) ?? false)) {
        return false;
      }
    }

    // 금액 범위
    if (_minAmount != null && receipt.amount < _minAmount!) return false;
    if (_maxAmount != null && receipt.amount > _maxAmount!) return false;

    return true;
  }).toList();
}
```

### 3.3. 복합 인덱스 전략

**자동 생성 접근**:
1. 복합 쿼리 실행 시 Firestore 에러 발생
2. 에러 메시지의 인덱스 생성 링크 클릭
3. Firebase Console에서 자동 생성

**장점**:
- 필요한 인덱스만 생성
- 유지보수 용이
- 개발 중 동적 조정 가능

---

## 4. 리스크 및 대응 방안

### 리스크 1: Firestore 복합 인덱스 누락
- **영향**: 쿼리 실패, 기능 작동 불가
- **대응**:
  - 개발 환경에서 먼저 인덱스 생성 테스트
  - 에러 핸들링 추가 (인덱스 없을 시 안내 메시지)
  - Firebase Console 인덱스 자동 생성 링크 활용

### 리스크 2: 클라이언트 측 필터링 성능 저하
- **영향**: 영수증 수가 많을 때 느린 검색
- **대응**:
  - 쿼리 결과 100개 제한 (`.limit(100)`)
  - Phase 2에서 페이지네이션 도입
  - 장기적으로 Algolia/Elasticsearch 고려

### 리스크 3: Debounce 타이머 메모리 누수
- **영향**: 메모리 누수, 앱 성능 저하
- **대응**:
  - `dispose()` 메서드에서 타이머 정리
  - Widget 테스트로 메모리 누수 확인

### 리스크 4: 날짜/금액 범위 검증 누락
- **영향**: 잘못된 범위로 검색 실패
- **대응**:
  - UI 단계에서 범위 검증 (시작 ≤ 끝)
  - 에러 메시지 표시

---

## 5. 테스트 전략

### 5.1. 단위 테스트
- Debounce 로직 테스트
- 클라이언트 필터링 로직 테스트
- 쿼리 빌더 로직 테스트

### 5.2. 통합 테스트
- Firestore 쿼리 실행 테스트 (Emulator 사용)
- 복합 필터 조합 테스트

### 5.3. 위젯 테스트
- 검색 입력 필드 테스트
- 필터 UI 상호작용 테스트
- 배지 표시/제거 테스트

### 5.4. 성능 테스트
- 100개 영수증 로드 시간 측정
- Debounce 지연 시간 확인

---

## 6. 다음 단계 안내

### TDD 구현 시작
```bash
/alfred:2-build SPEC-RECEIPT-004
```

### 구현 완료 후 문서 동기화
```bash
/alfred:3-sync
```

### 추가 개선 사항
- Phase 2: Full-text search (Algolia 연동)
- Phase 2: 페이지네이션
- Phase 2: 저장된 필터 프리셋

---

**작성자**: @edward
**작성일**: 2025-10-18
**버전**: 0.0.1
