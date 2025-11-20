# SPEC-RECEIPT-004 수락 기준

> **영수증 검색 및 필터링 기능 Acceptance Criteria**
>
> SPEC ID: RECEIPT-004
> Version: 0.0.1
> Status: draft

---

## 1. 수락 기준 개요

본 문서는 SPEC-RECEIPT-004의 구현 완료를 검증하기 위한 상세한 수락 기준을 정의합니다. 모든 시나리오는 **Given-When-Then** 형식을 따르며, 자동화된 테스트로 검증됩니다.

---

## 2. 기능별 수락 시나리오

### 2.1. 키워드 검색 (Debounce)

#### AC-001: 키워드 검색 정상 동작
**Given**: 사용자가 영수증 목록 페이지에 있음
**And**: 다음 영수증이 존재함:
- Receipt 1: businessPurpose = "팀 회의 식사"
- Receipt 2: businessPurpose = "출장 교통비"
- Receipt 3: businessPurpose = "회의실 간식"

**When**: 검색 입력 필드에 "회의" 키워드 입력
**And**: 300ms 대기
**Then**: Receipt 1, Receipt 3만 표시됨
**And**: Receipt 2는 표시되지 않음

#### AC-002: Debounce 타이머 동작
**Given**: 사용자가 검색 입력 필드에 포커스
**When**: "회" 입력 후 200ms 대기
**And**: "의" 추가 입력
**Then**: 검색 실행되지 않음 (타이머 리셋)
**When**: 300ms 추가 대기
**Then**: "회의" 키워드로 검색 실행됨

#### AC-003: 빈 키워드 검색
**Given**: 사용자가 영수증 목록 페이지에 있음
**When**: 검색 입력 필드를 비움
**Then**: 모든 영수증이 표시됨

#### AC-004: 대소문자 구분 없는 검색
**Given**: 영수증의 businessPurpose = "팀 회의 식사"
**When**: "회의" 또는 "會議" 키워드 입력 (대소문자 무관)
**Then**: 해당 영수증이 표시됨

---

### 2.2. 카테고리 필터

#### AC-005: 카테고리 필터 단일 선택
**Given**: 사용자가 영수증 목록 페이지에 있음
**And**: 다음 영수증이 존재함:
- Receipt 1: category = "식비"
- Receipt 2: category = "교통"
- Receipt 3: category = "식비"

**When**: 카테고리 드롭다운에서 "식비" 선택
**Then**: Receipt 1, Receipt 3만 표시됨
**And**: Receipt 2는 표시되지 않음

#### AC-006: 카테고리 필터 해제
**Given**: 카테고리 "식비"가 선택된 상태
**When**: 카테고리 선택 해제
**Then**: 모든 카테고리의 영수증이 표시됨

#### AC-007: 카테고리 필터 배지 표시
**Given**: 카테고리 "교통" 선택
**Then**: "카테고리: 교통" 배지가 표시됨
**When**: 배지의 X 아이콘 클릭
**Then**: 카테고리 필터가 해제됨

---

### 2.3. 날짜 범위 필터

#### AC-008: 날짜 범위 필터 정상 동작
**Given**: 사용자가 영수증 목록 페이지에 있음
**And**: 다음 영수증이 존재함:
- Receipt 1: receiptDate = 2025-10-05
- Receipt 2: receiptDate = 2025-10-15
- Receipt 3: receiptDate = 2025-11-01

**When**: 시작일 2025-10-01, 종료일 2025-10-31 선택
**Then**: Receipt 1, Receipt 2만 표시됨
**And**: Receipt 3는 표시되지 않음

#### AC-009: 시작일만 지정
**Given**: 영수증 Receipt 1 (2025-10-05), Receipt 2 (2025-10-15) 존재
**When**: 시작일만 2025-10-10 선택
**Then**: Receipt 2만 표시됨

#### AC-010: 종료일만 지정
**Given**: 영수증 Receipt 1 (2025-10-05), Receipt 2 (2025-10-15) 존재
**When**: 종료일만 2025-10-10 선택
**Then**: Receipt 1만 표시됨

#### AC-011: 잘못된 날짜 범위 방지
**Given**: 시작일 2025-10-31 선택됨
**When**: 종료일 날짜 선택 UI 열기
**Then**: 2025-10-31 이전 날짜는 선택 불가

#### AC-012: 날짜 범위 필터 배지
**Given**: 시작일 2025-10-01, 종료일 2025-10-31 선택
**Then**: "날짜: 10/01 ~ 10/31" 배지 표시됨
**When**: 배지의 X 아이콘 클릭
**Then**: 날짜 필터가 해제됨

---

### 2.4. 금액 범위 필터

#### AC-013: 금액 범위 필터 정상 동작
**Given**: 사용자가 영수증 목록 페이지에 있음
**And**: 다음 영수증이 존재함:
- Receipt 1: amount = 5,000원
- Receipt 2: amount = 15,000원
- Receipt 3: amount = 50,000원

**When**: 최소 금액 10,000원, 최대 금액 30,000원 입력
**Then**: Receipt 2만 표시됨
**And**: Receipt 1, Receipt 3는 표시되지 않음

#### AC-014: 최소 금액만 지정
**Given**: 영수증 Receipt 1 (5,000원), Receipt 2 (15,000원) 존재
**When**: 최소 금액 10,000원만 입력
**Then**: Receipt 2만 표시됨

#### AC-015: 최대 금액만 지정
**Given**: 영수증 Receipt 1 (5,000원), Receipt 2 (15,000원) 존재
**When**: 최대 금액 10,000원만 입력
**Then**: Receipt 1만 표시됨

#### AC-016: 잘못된 금액 범위 입력 방지
**Given**: 최소 금액 10,000원 입력됨
**When**: 최대 금액 5,000원 입력 시도
**Then**: 에러 메시지 "최대 금액은 최소 금액보다 커야 합니다" 표시

#### AC-017: 금액 범위 필터 배지
**Given**: 최소 10,000원, 최대 50,000원 입력
**Then**: "금액: 10,000 ~ 50,000" 배지 표시됨
**When**: 배지의 X 아이콘 클릭
**Then**: 금액 필터가 해제됨

---

### 2.5. 상태 필터 (제출 여부)

#### AC-018: "제출됨" 상태 필터
**Given**: 사용자가 영수증 목록 페이지에 있음
**And**: 다음 영수증이 존재함:
- Receipt 1: isSubmitted = true
- Receipt 2: isSubmitted = false
- Receipt 3: isSubmitted = true

**When**: "제출됨" 버튼 클릭
**Then**: Receipt 1, Receipt 3만 표시됨
**And**: "제출됨" 버튼이 활성화 스타일로 표시됨

#### AC-019: "대기중" 상태 필터
**Given**: 영수증 Receipt 1 (제출됨), Receipt 2 (대기중) 존재
**When**: "대기중" 버튼 클릭
**Then**: Receipt 2만 표시됨
**And**: "대기중" 버튼이 활성화 스타일로 표시됨

#### AC-020: 상태 필터 토글
**Given**: "제출됨" 상태 선택됨
**When**: "제출됨" 버튼 다시 클릭
**Then**: 상태 필터 해제됨
**And**: 모든 영수증 표시됨

#### AC-021: 상태 필터 배지
**Given**: "대기중" 상태 선택됨
**Then**: "상태: 대기중" 배지 표시됨
**When**: 배지의 X 아이콘 클릭
**Then**: 상태 필터 해제됨

---

### 2.6. 복합 필터

#### AC-022: 카테고리 + 날짜 복합 필터
**Given**: 사용자가 영수증 목록 페이지에 있음
**And**: 다음 영수증이 존재함:
- Receipt 1: category = "식비", receiptDate = 2025-10-05
- Receipt 2: category = "교통", receiptDate = 2025-10-15
- Receipt 3: category = "식비", receiptDate = 2025-11-01

**When**: 카테고리 "식비" + 날짜 범위 2025-10-01 ~ 2025-10-31 선택
**Then**: Receipt 1만 표시됨

#### AC-023: 키워드 + 카테고리 + 금액 복합 필터
**Given**: 다음 영수증이 존재함:
- Receipt 1: businessPurpose = "회의 식사", category = "식비", amount = 15,000원
- Receipt 2: businessPurpose = "출장 회의", category = "교통", amount = 20,000원
- Receipt 3: businessPurpose = "팀 회의", category = "식비", amount = 5,000원

**When**: 키워드 "회의" + 카테고리 "식비" + 최소 금액 10,000원 입력
**Then**: Receipt 1만 표시됨

#### AC-024: 모든 필터 조합
**Given**: 다양한 영수증 데이터 존재
**When**: 키워드 + 카테고리 + 날짜 + 금액 + 상태 모두 입력
**Then**: 모든 조건을 만족하는 영수증만 표시됨
**And**: 5개의 필터 배지가 표시됨

---

### 2.7. 필터 초기화

#### AC-025: "초기화" 버튼 동작
**Given**: 다음 필터가 적용됨:
- 키워드: "회의"
- 카테고리: "식비"
- 날짜 범위: 2025-10-01 ~ 2025-10-31
- 금액 범위: 10,000 ~ 50,000
- 상태: 제출됨

**When**: "초기화" 버튼 클릭
**Then**: 모든 필터가 제거됨
**And**: 모든 필터 배지가 사라짐
**And**: 전체 영수증 목록이 표시됨

#### AC-026: 초기화 후 재필터링
**Given**: 필터 초기화 완료
**When**: 새로운 필터 조건 입력
**Then**: 새로운 필터가 정상 동작함

---

### 2.8. 검색 결과 없음

#### AC-027: 검색 결과 0개
**Given**: 사용자가 영수증 목록 페이지에 있음
**When**: 검색 조건에 맞는 영수증이 없음
**Then**: "검색 결과가 없습니다" 메시지 표시됨
**And**: 빈 상태 일러스트레이션 표시 (선택)

#### AC-028: 검색 결과 없음 → 필터 제거
**Given**: 검색 결과 0개 상태
**When**: 필터 일부 제거
**Then**: 조건에 맞는 영수증이 표시됨

---

### 2.9. 성능 및 UX

#### AC-029: 검색 로딩 인디케이터
**Given**: 사용자가 필터 조건 변경
**When**: Firestore 쿼리 실행 중
**Then**: 로딩 스피너 또는 스켈레톤 UI 표시됨

#### AC-030: Debounce 중 타이핑 표시
**Given**: 사용자가 키워드 입력 중
**When**: Debounce 타이머 대기 중
**Then**: 입력 필드에 타이핑 내용이 실시간 표시됨
**And**: 검색 실행은 300ms 후

#### AC-031: 쿼리 결과 제한
**Given**: 데이터베이스에 200개 영수증 존재
**When**: 필터 없이 전체 조회
**Then**: 최대 100개만 표시됨
**And**: "더 많은 결과는 필터를 사용하세요" 안내 메시지 표시 (선택)

---

## 3. 품질 게이트 기준

### 3.1. 테스트 커버리지
- [ ] 단위 테스트 커버리지 ≥ 85%
- [ ] 위젯 테스트 커버리지 ≥ 75%
- [ ] 통합 테스트 커버리지 ≥ 70%

### 3.2. 성능 기준
- [ ] 검색 결과 반환 시간 ≤ 500ms (100개 문서 기준)
- [ ] Debounce 지연 시간 = 300ms (±10ms)
- [ ] UI 응답성: 필터 변경 시 즉시 반영 (0ms)

### 3.3. 접근성
- [ ] 키보드 네비게이션 지원 (Tab, Enter)
- [ ] 스크린 리더 호환 (Semantics 위젯)
- [ ] 포커스 표시 (Focus 상태 시각화)

### 3.4. 에러 처리
- [ ] Firestore 인덱스 누락 시 안내 메시지
- [ ] 네트워크 오류 시 재시도 옵션
- [ ] 잘못된 입력 값 방지 (클라이언트 검증)

---

## 4. 검증 방법

### 4.1. 자동화 테스트

**단위 테스트**:
```dart
// tests/receipts/receipt_search_test.dart
test('키워드 검색 - businessPurpose 필터링', () {
  final receipts = [
    ReceiptRecord(businessPurpose: '회의 식사', ...),
    ReceiptRecord(businessPurpose: '출장 교통', ...),
  ];
  final filtered = applyKeywordFilter(receipts, '회의');
  expect(filtered.length, 1);
  expect(filtered[0].businessPurpose, contains('회의'));
});
```

**위젯 테스트**:
```dart
testWidgets('카테고리 필터 드롭다운 선택', (tester) async {
  await tester.pumpWidget(ReceiptSearchPage());
  await tester.tap(find.byType(ShadSelect));
  await tester.pumpAndSettle();
  await tester.tap(find.text('식비'));
  await tester.pumpAndSettle();

  expect(find.byType(ShadBadge), findsOneWidget);
  expect(find.text('카테고리: 식비'), findsOneWidget);
});
```

**통합 테스트**:
```dart
testWidgets('복합 필터 - Firestore 쿼리 실행', (tester) async {
  await FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  // 테스트 데이터 생성
  // 필터 적용
  // 결과 검증
});
```

### 4.2. 수동 테스트

**체크리스트**:
- [ ] 모든 필터 조합 시나리오 테스트
- [ ] 브라우저 호환성 (Chrome, Safari, Edge)
- [ ] 반응형 레이아웃 확인 (모바일, 태블릿, 데스크톱)
- [ ] 접근성 도구로 검증 (Lighthouse)

---

## 5. 완료 조건 (Definition of Done)

### 5.1. 기능 완료
- [ ] 모든 수락 시나리오 통과
- [ ] Firestore 복합 인덱스 생성 완료
- [ ] 에러 핸들링 구현 완료

### 5.2. 코드 품질
- [ ] TRUST 5원칙 준수
- [ ] 코드 리뷰 완료 (자가 리뷰 또는 팀 리뷰)
- [ ] @TAG 주석 추가 완료

### 5.3. 문서화
- [ ] `/alfred:3-sync` 실행 완료
- [ ] TAG 체인 검증 완료
- [ ] Living Document 업데이트 완료

### 5.4. 배포 준비
- [ ] Firebase 프로덕션 환경 인덱스 생성
- [ ] 성능 테스트 완료
- [ ] 보안 검토 완료 (Firestore 규칙 검증)

---

**작성자**: @edward
**작성일**: 2025-10-18
**버전**: 0.0.1
