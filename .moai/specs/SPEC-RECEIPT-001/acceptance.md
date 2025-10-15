# SPEC-RECEIPT-001 인수 기준 (Acceptance Criteria)

> **Receipt Upload & Basic Flow - Employee Web App MVP**
>
> Given-When-Then 형식의 상세 검증 시나리오

---

## 1. 인수 기준 개요

### 목적
이 문서는 SPEC-RECEIPT-001이 완료되었는지 검증하기 위한 구체적인 시나리오를 정의합니다. 모든 시나리오는 Given-When-Then 형식을 따릅니다.

### 검증 방법
- **단위 테스트**: Flutter Test로 자동 검증
- **통합 테스트**: Firebase Emulator 기반 E2E 테스트
- **수동 테스트**: 실제 브라우저에서 사용자 시나리오 실행
- **보안 규칙 테스트**: @firebase/rules-unit-testing으로 자동 검증

### 통과 기준
- 모든 자동화 테스트 통과 (100%)
- 수동 테스트 체크리스트 완료
- SPEC의 모든 EARS 요구사항 충족

---

## 2. Firebase Storage 업로드 시나리오

### AC-1: 유효한 영수증 이미지 업로드 성공

**우선순위**: Critical
**테스트 파일**: `tests/services/storage_service_test.dart`

```gherkin
Given 직원이 Firebase Authentication으로 로그인한 상태이고
  And 유효한 JPG 이미지 파일(2MB, image/jpeg)을 선택했을 때
When StorageService.uploadReceiptImage(file, userId, receiptId)를 호출하면
Then Firebase Storage에 파일이 업로드되고
  And 다운로드 URL이 반환되며
  And 반환된 URL은 "gs://receipt-flow-test.appspot.com/receipts/{userId}/{receiptId}/image.jpg" 패턴을 따른다
```

**검증 코드**:
```dart
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
test('AC-1: 유효한 영수증 이미지 업로드 성공', () async {
  // Given
  final userId = 'test-user-123';
  final receiptId = 'receipt-456';
  final mockFile = MockFile(
    bytes: Uint8List(2 * 1024 * 1024), // 2MB
    mimeType: 'image/jpeg',
  );

  // When
  final result = await storageService.uploadReceiptImage(
    mockFile,
    userId,
    receiptId,
  );

  // Then
  expect(result.isSuccess, true);
  expect(result.data, startsWith('https://firebasestorage.googleapis.com'));
  expect(result.data, contains('receipts%2F$userId%2F$receiptId'));
});
```

---

### AC-2: 파일 크기 초과 시 업로드 차단

**우선순위**: High
**테스트 파일**: `tests/services/storage_service_test.dart`

```gherkin
Given 직원이 로그인한 상태이고
  And 11MB 크기의 이미지 파일을 선택했을 때
When uploadReceiptImage를 호출하면
Then FileTooLargeException이 발생하고
  And 에러 메시지는 "파일 크기는 10MB 이하여야 합니다"를 포함한다
```

**검증 코드**:
```dart
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
test('AC-2: 파일 크기 초과 시 업로드 차단', () async {
  // Given
  final largeFile = MockFile(
    bytes: Uint8List(11 * 1024 * 1024), // 11MB
    mimeType: 'image/jpeg',
  );

  // When & Then
  expect(
    () => storageService.uploadReceiptImage(largeFile, userId, receiptId),
    throwsA(isA<FileTooLargeException>()),
  );
});
```

---

### AC-3: 허용되지 않은 파일 형식 거부

**우선순위**: High
**테스트 파일**: `tests/services/storage_service_test.dart`

```gherkin
Given 직원이 로그인한 상태이고
  And .txt 파일(text/plain)을 선택했을 때
When uploadReceiptImage를 호출하면
Then InvalidFileTypeException이 발생하고
  And 에러 메시지는 "JPG, PNG, PDF 파일만 업로드 가능합니다"를 포함한다
```

**검증 코드**:
```dart
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
test('AC-3: 허용되지 않은 파일 형식 거부', () async {
  // Given
  final invalidFile = MockFile(
    bytes: Uint8List(1024),
    mimeType: 'text/plain', // 허용되지 않은 형식
  );

  // When & Then
  expect(
    () => storageService.uploadReceiptImage(invalidFile, userId, receiptId),
    throwsA(isA<InvalidFileTypeException>()),
  );
});
```

---

## 3. Firestore CRUD 시나리오

### AC-4: 영수증 생성 성공 (필수 필드 포함)

**우선순위**: Critical
**테스트 파일**: `tests/services/firestore_service_test.dart`

```gherkin
Given 직원이 로그인한 상태이고
  And 영수증 이미지가 Firebase Storage에 업로드되어 imageUrl을 획득했으며
  And 필수 정보(날짜: 2025-10-14, 금액: 25000원)를 입력했을 때
When FirestoreService.createReceipt(receiptData)를 호출하면
Then Firestore receipts 컬렉션에 새 문서가 생성되고
  And 문서 ID가 반환되며
  And createdAt 필드는 서버 타임스탬프로 자동 설정되고
  And isSubmitted 필드는 true로 설정된다
```

**검증 코드**:
```dart
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
test('AC-4: 영수증 생성 성공', () async {
  // Given
  final receiptData = {
    'userId': testUserId,
    'imageUrl': 'https://storage.googleapis.com/test/image.jpg',
    'amount': 25000.0,
    'date': Timestamp.fromDate(DateTime(2025, 10, 14)),
    'category': '식비',
    'businessPurpose': '고객 미팅',
  };

  // When
  final receiptId = await firestoreService.createReceipt(receiptData);

  // Then
  expect(receiptId, isNotEmpty);

  final snapshot = await FirebaseFirestore.instance
      .collection('receipts')
      .doc(receiptId)
      .get();

  expect(snapshot.exists, true);
  expect(snapshot.data()!['userId'], testUserId);
  expect(snapshot.data()!['amount'], 25000.0);
  expect(snapshot.data()!['isSubmitted'], true);
  expect(snapshot.data()!['createdAt'], isA<Timestamp>());
});
```

---

### AC-5: 필수 필드 누락 시 생성 차단

**우선순위**: High
**테스트 파일**: `tests/services/firestore_service_test.dart`

```gherkin
Given 직원이 로그인한 상태이고
  And 영수증 데이터에서 amount 필드가 누락되었을 때
When createReceipt를 호출하면
Then MissingRequiredFieldException이 발생하고
  And 에러 메시지는 "필수 필드(날짜, 금액)가 누락되었습니다"를 포함한다
```

**검증 코드**:
```dart
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
test('AC-5: 필수 필드 누락 시 생성 차단', () async {
  // Given
  final invalidData = {
    'userId': testUserId,
    'imageUrl': 'https://storage.googleapis.com/test/image.jpg',
    'date': Timestamp.now(),
    // amount 필드 누락
  };

  // When & Then
  expect(
    () => firestoreService.createReceipt(invalidData),
    throwsA(isA<MissingRequiredFieldException>()),
  );
});
```

---

### AC-6: 본인 영수증만 조회 가능 (필터링)

**우선순위**: Critical
**테스트 파일**: `tests/services/firestore_service_test.dart`

```gherkin
Given User A와 User B가 각각 영수증을 제출한 상태이고
  And User A로 로그인했을 때
When FirestoreService.getReceipts(userA.uid)를 호출하면
Then User A의 영수증만 반환되고
  And User B의 영수증은 포함되지 않는다
```

**검증 코드**:
```dart
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
test('AC-6: 본인 영수증만 조회 가능', () async {
  // Given
  final userA = 'user-a-123';
  final userB = 'user-b-456';

  await firestoreService.createReceipt({
    'userId': userA,
    'imageUrl': 'https://test.com/a.jpg',
    'amount': 10000,
    'date': Timestamp.now(),
  });

  await firestoreService.createReceipt({
    'userId': userB,
    'imageUrl': 'https://test.com/b.jpg',
    'amount': 20000,
    'date': Timestamp.now(),
  });

  // When
  final receiptsA = await firestoreService.getReceipts(userA).first;

  // Then
  expect(receiptsA.length, 1);
  expect(receiptsA.every((r) => r.userId == userA), true);
});
```

---

### AC-7: 제출된 영수증 수정 불가

**우선순위**: High
**테스트 파일**: `tests/services/firestore_service_test.dart`

```gherkin
Given 직원이 영수증을 제출하여 isSubmitted = true 상태이고
When 해당 영수증의 amount를 수정하려고 시도하면
Then PermissionDeniedException이 발생하거나
  And Firestore 보안 규칙이 요청을 거부한다
```

**검증 코드**:
```dart
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
test('AC-7: 제출된 영수증 수정 불가', () async {
  // Given
  final receiptId = await firestoreService.createReceipt({
    'userId': testUserId,
    'imageUrl': 'https://test.com/image.jpg',
    'amount': 10000,
    'date': Timestamp.now(),
    'isSubmitted': true,
  });

  // When & Then
  expect(
    () => firestoreService.updateReceipt(receiptId, {'amount': 20000}),
    throwsA(isA<PermissionDeniedException>()),
  );
});
```

---

## 4. UI 동작 시나리오 (Widget Tests)

### AC-8: 파일 선택 버튼 동작

**우선순위**: High
**테스트 파일**: `tests/pages/receipt_upload_page_test.dart`

```gherkin
Given ReceiptUploadPage가 렌더링된 상태이고
When "파일 선택" 버튼을 클릭하면
Then FilePicker.platform.pickFiles()가 호출되고
  And 파일 선택 다이얼로그가 열린다
```

**검증 코드**:
```dart
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
testWidgets('AC-8: 파일 선택 버튼 동작', (tester) async {
  // Given
  await tester.pumpWidget(MaterialApp(home: ReceiptUploadPage()));

  // When
  final filePickerButton = find.text('파일 선택');
  await tester.tap(filePickerButton);
  await tester.pumpAndSettle();

  // Then
  verify(mockFilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['jpg', 'png', 'pdf'],
  )).called(1);
});
```

---

### AC-9: 필수 필드 누락 시 제출 버튼 비활성화

**우선순위**: High
**테스트 파일**: `tests/pages/receipt_upload_page_test.dart`

```gherkin
Given ReceiptUploadPage에서 파일은 선택했지만
  And amount 필드가 비어있을 때
When 제출 버튼 상태를 확인하면
Then 제출 버튼이 비활성화(disabled) 상태이고
  And 클릭해도 제출되지 않는다
```

**검증 코드**:
```dart
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
testWidgets('AC-9: 필수 필드 누락 시 제출 버튼 비활성화', (tester) async {
  // Given
  await tester.pumpWidget(MaterialApp(home: ReceiptUploadPage()));

  // 파일 선택 (imageUrl 설정됨)
  // amount 필드는 비워둠

  // When
  final submitButton = find.widgetWithText(ElevatedButton, '제출');

  // Then
  final button = tester.widget<ElevatedButton>(submitButton);
  expect(button.enabled, false);
});
```

---

### AC-10: 업로드 진행률 표시

**우선순위**: Medium
**테스트 파일**: `tests/pages/receipt_upload_page_test.dart`

```gherkin
Given 직원이 3MB 이미지 파일을 선택하고
When 업로드를 시작하면
Then CircularProgressIndicator가 표시되고
  And 진행률(0% → 100%)이 업데이트되며
  And 완료 시 미리보기 이미지가 표시된다
```

**검증 코드**:
```dart
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
testWidgets('AC-10: 업로드 진행률 표시', (tester) async {
  // Given
  await tester.pumpWidget(MaterialApp(home: ReceiptUploadPage()));
  final mockFile = MockFile(bytes: Uint8List(3 * 1024 * 1024));

  // When
  await tester.tap(find.text('파일 선택'));
  await tester.pumpAndSettle();

  // Then
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  // 업로드 완료 후
  await tester.pumpAndSettle(Duration(seconds: 5));
  expect(find.byType(CachedNetworkImage), findsOneWidget);
});
```

---

## 5. 실시간 목록 조회 시나리오 (StreamBuilder)

### AC-11: Firestore 변경 시 실시간 UI 업데이트

**우선순위**: Critical
**테스트 파일**: `tests/pages/receipt_list_page_test.dart`

```gherkin
Given ReceiptListPage가 렌더링된 상태이고
  And 초기 영수증 목록이 2개 표시되고 있을 때
When 다른 세션에서 새 영수증을 추가하면
Then StreamBuilder가 자동으로 새 데이터를 수신하고
  And 목록이 3개로 업데이트되며
  And 화면을 새로고침하지 않아도 반영된다
```

**검증 코드**:
```dart
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
testWidgets('AC-11: Firestore 변경 시 실시간 UI 업데이트', (tester) async {
  // Given
  await tester.pumpWidget(MaterialApp(home: ReceiptListPage()));
  await tester.pumpAndSettle();

  expect(find.byType(ReceiptCard), findsNWidgets(2));

  // When (다른 세션에서 추가)
  await firestoreService.createReceipt({
    'userId': testUserId,
    'imageUrl': 'https://test.com/new.jpg',
    'amount': 30000,
    'date': Timestamp.now(),
  });

  await tester.pump(); // StreamBuilder 업데이트 대기

  // Then
  expect(find.byType(ReceiptCard), findsNWidgets(3));
});
```

---

### AC-12: 날짜 역순 정렬

**우선순위**: Medium
**테스트 파일**: `tests/services/firestore_service_test.dart`

```gherkin
Given 직원이 영수증 3개를 서로 다른 날짜에 제출했고
  And 제출 순서가 2025-10-10, 2025-10-12, 2025-10-14일 때
When ReceiptListPage에서 목록을 조회하면
Then 최신 영수증(2025-10-14)이 맨 위에 표시되고
  And 오래된 영수증(2025-10-10)이 맨 아래에 표시된다
```

**검증 코드**:
```dart
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
test('AC-12: 날짜 역순 정렬', () async {
  // Given
  await firestoreService.createReceipt({
    'userId': testUserId,
    'date': Timestamp.fromDate(DateTime(2025, 10, 10)),
    'amount': 10000,
    'imageUrl': 'https://test.com/1.jpg',
  });

  await firestoreService.createReceipt({
    'userId': testUserId,
    'date': Timestamp.fromDate(DateTime(2025, 10, 14)),
    'amount': 30000,
    'imageUrl': 'https://test.com/3.jpg',
  });

  // When
  final receipts = await firestoreService
      .getReceipts(testUserId)
      .first;

  // Then
  expect(receipts[0].date, DateTime(2025, 10, 14)); // 최신
  expect(receipts[1].date, DateTime(2025, 10, 10)); // 오래됨
});
```

---

## 6. 보안 규칙 시나리오

### AC-13: 인증되지 않은 사용자 접근 차단

**우선순위**: Critical
**테스트 파일**: `tests/security/firestore_rules_test.dart`

```gherkin
Given 사용자가 로그아웃한 상태(request.auth == null)이고
When Firestore.collection('receipts').get()을 호출하면
Then permission-denied 에러가 발생하고
  And 데이터에 접근할 수 없다
```

**검증 코드**:
```javascript
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
// Node.js 테스트 (@firebase/rules-unit-testing)
test('AC-13: 인증되지 않은 사용자 접근 차단', async () => {
  const db = testEnv.unauthenticatedContext().firestore();

  await assertFails(
    db.collection('receipts').get()
  );
});
```

---

### AC-14: 다른 사용자 영수증 접근 차단

**우선순위**: Critical
**테스트 파일**: `tests/security/firestore_rules_test.dart`

```gherkin
Given User A가 로그인한 상태이고
  And User B의 영수증 문서 ID를 알고 있을 때
When User A가 User B의 영수증을 조회하려고 시도하면
Then permission-denied 에러가 발생하고
  And Firestore 보안 규칙이 요청을 거부한다
```

**검증 코드**:
```javascript
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
test('AC-14: 다른 사용자 영수증 접근 차단', async () => {
  const userADb = testEnv.authenticatedContext('user-a').firestore();

  // User B의 영수증 미리 생성
  const userBDb = testEnv.authenticatedContext('user-b').firestore();
  const receiptRef = await userBDb.collection('receipts').add({
    userId: 'user-b',
    amount: 10000,
    imageUrl: 'https://test.com/b.jpg',
    date: firestore.Timestamp.now(),
  });

  // User A가 User B 영수증 조회 시도
  await assertFails(
    userADb.collection('receipts').doc(receiptRef.id).get()
  );
});
```

---

### AC-15: Storage 보안 규칙 - 파일 크기 제한

**우선순위**: High
**테스트 파일**: `tests/security/storage_rules_test.dart`

```gherkin
Given 직원이 로그인한 상태이고
When 11MB 크기의 파일을 Firebase Storage에 업로드하려고 시도하면
Then Storage 보안 규칙이 요청을 거부하고
  And permission-denied 에러가 발생한다
```

**검증 코드**:
```javascript
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
test('AC-15: Storage 파일 크기 제한', async () => {
  const storage = testEnv.authenticatedContext('user-a').storage();
  const largeFile = Buffer.alloc(11 * 1024 * 1024); // 11MB

  await assertFails(
    storage.ref('receipts/user-a/receipt-123/image.jpg').put(largeFile)
  );
});
```

---

## 7. Record/Snapshot 패턴 검증

### AC-16: DocumentSnapshot → ReceiptRecord 변환 정확성

**우선순위**: High
**테스트 파일**: `tests/models/receipt_record_test.dart`

```gherkin
Given Firestore DocumentSnapshot이 다음 데이터를 포함하고
  {
    "userId": "user-123",
    "amount": 25000.5,
    "date": Timestamp(2025-10-14),
    "imageUrl": "https://test.com/image.jpg",
    "createdAt": Timestamp(2025-10-14 10:30:00),
    "isSubmitted": true
  }
When ReceiptRecord.fromSnapshot(snapshot)을 호출하면
Then 모든 필드가 정확히 타입 변환되고
  And amount는 double 타입이며
  And date와 createdAt는 DateTime 타입이고
  And id는 snapshot.id와 일치한다
```

**검증 코드**:
```dart
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
test('AC-16: DocumentSnapshot → ReceiptRecord 변환', () {
  // Given
  final mockSnapshot = MockDocumentSnapshot(
    id: 'receipt-123',
    data: {
      'userId': 'user-123',
      'amount': 25000.5,
      'date': Timestamp.fromDate(DateTime(2025, 10, 14)),
      'imageUrl': 'https://test.com/image.jpg',
      'createdAt': Timestamp.fromDate(DateTime(2025, 10, 14, 10, 30)),
      'isSubmitted': true,
    },
  );

  // When
  final record = ReceiptRecord.fromSnapshot(mockSnapshot);

  // Then
  expect(record.id, 'receipt-123');
  expect(record.userId, 'user-123');
  expect(record.amount, 25000.5);
  expect(record.amount, isA<double>());
  expect(record.date, DateTime(2025, 10, 14));
  expect(record.createdAt, DateTime(2025, 10, 14, 10, 30));
  expect(record.isSubmitted, true);
});
```

---

## 8. 수동 테스트 체크리스트

### 브라우저 호환성 테스트

**테스트 환경**: Chrome, Safari, Edge

- [ ] **Chrome 최신 버전**:
  - [ ] 로그인 성공
  - [ ] 파일 선택 다이얼로그 정상 동작
  - [ ] 업로드 진행률 표시
  - [ ] 목록 페이지 실시간 업데이트

- [ ] **Safari 최신 버전**:
  - [ ] 파일 업로드 동작
  - [ ] UI 레이아웃 정상 표시
  - [ ] shadcn_flutter 컴포넌트 렌더링

- [ ] **Edge 최신 버전**:
  - [ ] 전체 플로우 정상 동작

---

### End-to-End 플로우 테스트

**시나리오**: 실제 사용자 워크플로우

1. **로그인**:
   - [ ] 이메일/비밀번호 입력
   - [ ] 로그인 성공 시 ReceiptListPage 이동

2. **영수증 업로드**:
   - [ ] "새 영수증" 버튼 클릭
   - [ ] 파일 선택 (JPG 2MB)
   - [ ] 날짜 선택 (DatePicker)
   - [ ] 금액 입력 (25000원)
   - [ ] 카테고리 선택 (드롭다운)
   - [ ] 비즈니스 목적 입력
   - [ ] 제출 버튼 클릭
   - [ ] 성공 메시지 확인

3. **목록 조회**:
   - [ ] 방금 추가한 영수증이 맨 위에 표시
   - [ ] 이미지 썸네일 로딩
   - [ ] 금액/날짜 포맷팅 확인

4. **실시간 동기화**:
   - [ ] 다른 브라우저 탭에서 새 영수증 추가
   - [ ] 원래 탭에서 자동 업데이트 확인

5. **로그아웃**:
   - [ ] 로그아웃 버튼 클릭
   - [ ] 로그인 페이지로 이동

---

### 에러 처리 테스트

**예외 상황 시나리오**:

- [ ] **네트워크 오류**:
  - [ ] Wi-Fi 끊기 → 업로드 실패 메시지 확인
  - [ ] 재시도 로직 동작 확인

- [ ] **파일 크기 초과**:
  - [ ] 11MB 파일 선택 → 에러 메시지 표시
  - [ ] "파일 크기는 10MB 이하여야 합니다" 확인

- [ ] **잘못된 파일 형식**:
  - [ ] .txt 파일 선택 → 에러 메시지
  - [ ] "JPG, PNG, PDF 파일만 업로드 가능합니다" 확인

- [ ] **필수 필드 누락**:
  - [ ] 금액 입력 안 함 → 제출 버튼 비활성화
  - [ ] 활성화 조건 확인

---

## 9. Definition of Done (DoD)

### 자동화 테스트
- [ ] 모든 단위 테스트 통과 (16개 시나리오)
- [ ] 위젯 테스트 통과 (3개 시나리오)
- [ ] 보안 규칙 테스트 통과 (3개 시나리오)
- [ ] 통합 테스트 E2E 플로우 통과 (1개 시나리오)

### 수동 테스트
- [ ] 브라우저 호환성 체크리스트 완료
- [ ] End-to-End 플로우 체크리스트 완료
- [ ] 에러 처리 시나리오 검증 완료

### SPEC 준수
- [ ] EARS 요구사항 모두 구현 확인
- [ ] TAG 체인 무결성 검증
- [ ] TRUST 5원칙 준수 확인

### 문서화
- [ ] API 문서 생성 (dart doc)
- [ ] README.md 사용법 가이드 추가
- [ ] deployment.md 작성

---

## 10. 추적성 매트릭스

| AC ID | SPEC 요구사항 | 테스트 파일 | 구현 파일 | 상태 |
|-------|--------------|------------|----------|------|
| AC-1  | Event-driven: 파일 업로드 | storage_service_test.dart | storage_service.dart | ⏳ Pending |
| AC-2  | Constraints: 파일 크기 제한 | storage_service_test.dart | storage_service.dart | ⏳ Pending |
| AC-3  | Constraints: 파일 형식 검증 | storage_service_test.dart | storage_service.dart | ⏳ Pending |
| AC-4  | Event-driven: 영수증 생성 | firestore_service_test.dart | firestore_service.dart | ⏳ Pending |
| AC-5  | Constraints: 필수 필드 검증 | firestore_service_test.dart | firestore_service.dart | ⏳ Pending |
| AC-6  | Ubiquitous: 본인 영수증 조회 | firestore_service_test.dart | firestore_service.dart | ⏳ Pending |
| AC-7  | State-driven: 제출된 영수증 수정 불가 | firestore_service_test.dart | firestore_service.dart | ⏳ Pending |
| AC-8  | UI: 파일 선택 버튼 | receipt_upload_page_test.dart | receipt_upload_page.dart | ⏳ Pending |
| AC-9  | UI: 제출 버튼 비활성화 | receipt_upload_page_test.dart | receipt_upload_page.dart | ⏳ Pending |
| AC-10 | Event-driven: 업로드 진행률 | receipt_upload_page_test.dart | receipt_upload_page.dart | ⏳ Pending |
| AC-11 | Event-driven: 실시간 UI 업데이트 | receipt_list_page_test.dart | receipt_list_page.dart | ⏳ Pending |
| AC-12 | Ubiquitous: 날짜 역순 정렬 | firestore_service_test.dart | firestore_service.dart | ⏳ Pending |
| AC-13 | Security: 인증되지 않은 접근 차단 | firestore_rules_test.js | firestore.rules | ⏳ Pending |
| AC-14 | Security: 다른 사용자 영수증 차단 | firestore_rules_test.js | firestore.rules | ⏳ Pending |
| AC-15 | Security: Storage 파일 크기 제한 | storage_rules_test.js | storage.rules | ⏳ Pending |
| AC-16 | Architecture: Record/Snapshot 패턴 | receipt_record_test.dart | receipt_record.dart | ⏳ Pending |

**진행 상태 범례**:
- ⏳ Pending: 구현 대기
- 🔴 RED: 테스트 작성 완료, 실패 확인
- 🟢 GREEN: 구현 완료, 테스트 통과
- ♻️ REFACTOR: 리팩토링 완료

---

**작성일**: 2025-10-14
**작성자**: @edward (spec-builder 에이전트)
**관련 SPEC**: SPEC-RECEIPT-001.md
**관련 계획**: plan.md
