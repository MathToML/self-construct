# SPEC-RECEIPT-002 인수 기준

> **Given-When-Then 형식 테스트 시나리오**

---

## 개요

- **SPEC ID**: RECEIPT-002
- **목표**: 영수증 실시간 목록 조회 및 상세 업로드 기능의 완료 조건 정의
- **형식**: Given-When-Then (BDD)
- **검증 방법**: Flutter Widget Test + Integration Test

---

## 인수 시나리오

### 시나리오 1: 영수증 목록 실시간 조회

#### 1.1 정상 케이스 - 목록 표시

**Given**: 사용자 계정에 3개의 영수증이 등록되어 있음
- Receipt 1: storeName="스타벅스", date=2025-10-15
- Receipt 2: storeName="GS25", date=2025-10-14
- Receipt 3: storeName="올리브영", date=2025-10-13

**When**: 사용자가 영수증 목록 화면에 진입

**Then**:
- [ ] 목록이 날짜 내림차순으로 정렬되어 표시 (스타벅스 → GS25 → 올리브영)
- [ ] 각 영수증이 ReceiptCard 위젯으로 렌더링
- [ ] 상호명, 금액, 날짜, 카테고리가 올바르게 표시
- [ ] 이미지 썸네일이 80x80 크기로 표시
- [ ] FloatingActionButton이 우측 하단에 표시

**검증 코드**:
```dart
testWidgets('영수증 목록이 최신순으로 정렬되어 표시', (tester) async {
  // Given
  final receipts = [
    Receipt(storeName: '스타벅스', date: DateTime(2025, 10, 15)),
    Receipt(storeName: 'GS25', date: DateTime(2025, 10, 14)),
    Receipt(storeName: '올리브영', date: DateTime(2025, 10, 13)),
  ];
  final mockService = MockReceiptService();
  when(mockService.watchReceipts(any)).thenAnswer((_) => Stream.value(receipts));

  // When
  await tester.pumpWidget(ReceiptListPage());

  // Then
  expect(find.text('스타벅스'), findsOneWidget);
  expect(find.text('GS25'), findsOneWidget);
  expect(find.text('올리브영'), findsOneWidget);

  final starbucksWidget = find.text('스타벅스');
  final gs25Widget = find.text('GS25');
  expect(tester.getTopLeft(starbucksWidget).dy < tester.getTopLeft(gs25Widget).dy, true);
});
```

#### 1.2 예외 케이스 - 빈 목록

**Given**: 사용자 계정에 등록된 영수증이 없음

**When**: 사용자가 영수증 목록 화면에 진입

**Then**:
- [ ] "등록된 영수증이 없습니다" 메시지 표시
- [ ] FloatingActionButton은 여전히 표시
- [ ] 로딩 인디케이터가 표시되지 않음

#### 1.3 예외 케이스 - 네트워크 오류

**Given**: Firebase Realtime Database 연결 실패

**When**: 사용자가 영수증 목록 화면에 진입

**Then**:
- [ ] 에러 메시지 표시: "에러: [오류 내용]"
- [ ] 재시도 옵션 제공 (향후 개선)

#### 1.4 실시간 업데이트

**Given**: 영수증 목록 화면이 열려 있음

**When**: Firebase에서 새로운 영수증이 추가됨

**Then**:
- [ ] 1초 이내에 새 영수증이 목록 상단에 자동 추가
- [ ] 기존 목록이 아래로 이동
- [ ] 애니메이션 없이 즉시 반영

---

### 시나리오 2: 영수증 업로드 성공

#### 2.1 정상 케이스 - 모든 필드 입력

**Given**: 사용자가 영수증 업로드 화면에 진입

**When**: 다음 정보를 입력하고 "업로드" 버튼 클릭
- storeName: "이마트"
- totalAmount: "35000"
- date: 2025-10-15
- category: "식료품"
- imageFile: valid_receipt.jpg (2MB)

**Then**:
- [ ] 유효성 검증 통과
- [ ] receiptService.uploadReceipt() 호출
- [ ] 업로드 중 CircularProgressIndicator 표시
- [ ] 업로드 버튼 비활성화
- [ ] 업로드 완료 후 Navigator.pop() 실행
- [ ] 목록 화면으로 복귀 시 새 영수증이 상단에 표시

**검증 코드**:
```dart
testWidgets('업로드 성공 시 목록 화면 복귀', (tester) async {
  // Given
  await tester.pumpWidget(ReceiptUploadPage());
  await tester.enterText(find.byKey(Key('storeName')), '이마트');
  await tester.enterText(find.byKey(Key('totalAmount')), '35000');

  // When
  await tester.tap(find.text('업로드'));
  await tester.pumpAndSettle();

  // Then
  verify(mockReceiptService.uploadReceipt(any, any)).called(1);
  expect(find.byType(ReceiptListPage), findsOneWidget);
});
```

#### 2.2 이미지 미리보기

**Given**: 사용자가 "이미지 선택" 버튼 클릭

**When**: valid_receipt.jpg 파일 선택

**Then**:
- [ ] 선택된 이미지가 화면에 미리보기로 표시
- [ ] 이미지 크기 표시: "2.1 MB"
- [ ] "이미지 변경" 버튼 활성화

---

### 시나리오 3: 파일 크기 초과

#### 3.1 예외 케이스 - 5MB 초과

**Given**: 사용자가 영수증 업로드 화면에 진입

**When**: 6MB 크기의 이미지 파일 선택

**Then**:
- [ ] 파일 선택 즉시 차단
- [ ] SnackBar 표시: "파일 크기는 5MB를 초과할 수 없습니다"
- [ ] 이미지 미리보기가 표시되지 않음
- [ ] imageFile 상태가 null로 유지

**검증 코드**:
```dart
testWidgets('5MB 초과 파일 선택 시 에러 메시지 표시', (tester) async {
  // Given
  final largefile = File('test_assets/large_receipt.jpg'); // 6MB
  when(mockFilePicker.pickFiles(any)).thenAnswer((_) async => FilePickerResult([largefile]));

  // When
  await tester.tap(find.text('이미지 선택'));
  await tester.pumpAndSettle();

  // Then
  expect(find.text('파일 크기는 5MB를 초과할 수 없습니다'), findsOneWidget);
  expect(find.byType(Image), findsNothing);
});
```

#### 3.2 예외 케이스 - 지원하지 않는 형식

**Given**: 사용자가 "이미지 선택" 버튼 클릭

**When**: PDF 파일 선택 시도

**Then**:
- [ ] FilePicker가 jpg/png만 필터링
- [ ] PDF 파일이 선택 목록에 표시되지 않음

---

### 시나리오 4: 필수 필드 누락

#### 4.1 예외 케이스 - storeName 누락

**Given**: 사용자가 영수증 업로드 화면에서 totalAmount, date만 입력

**When**: storeName을 비우고 "업로드" 버튼 클릭

**Then**:
- [ ] 유효성 검증 실패
- [ ] storeName 필드 아래 에러 메시지 표시: "상호명을 입력해주세요"
- [ ] 업로드가 실행되지 않음
- [ ] 포커스가 storeName 필드로 이동

**검증 코드**:
```dart
testWidgets('필수 필드 누락 시 업로드 차단', (tester) async {
  // Given
  await tester.pumpWidget(ReceiptUploadPage());
  await tester.enterText(find.byKey(Key('totalAmount')), '10000');
  // storeName은 입력하지 않음

  // When
  await tester.tap(find.text('업로드'));
  await tester.pump();

  // Then
  expect(find.text('상호명을 입력해주세요'), findsOneWidget);
  verifyNever(mockReceiptService.uploadReceipt(any, any));
});
```

#### 4.2 예외 케이스 - totalAmount 형식 오류

**Given**: 사용자가 totalAmount 필드에 "abc" 입력

**When**: "업로드" 버튼 클릭

**Then**:
- [ ] 유효성 검증 실패
- [ ] 에러 메시지: "올바른 금액을 입력해주세요"
- [ ] 업로드가 실행되지 않음

#### 4.3 예외 케이스 - 이미지 미선택

**Given**: 사용자가 storeName, totalAmount, date만 입력

**When**: 이미지를 선택하지 않고 "업로드" 버튼 클릭

**Then**:
- [ ] SnackBar 표시: "이미지를 선택해주세요"
- [ ] 업로드가 실행되지 않음

---

## 통합 테스트 시나리오

### End-to-End 플로우

**Given**: 앱을 처음 실행하고 로그인 완료

**When**: 다음 작업을 순차적으로 수행
1. 영수증 목록 화면 진입 (빈 목록)
2. FloatingActionButton 클릭
3. 업로드 화면에서 정보 입력 및 업로드
4. 목록 화면 복귀

**Then**:
- [ ] 빈 목록 메시지 → 업로드 화면 → 목록에 새 영수증 표시
- [ ] 전체 플로우가 20초 이내에 완료
- [ ] 각 화면 전환이 부드럽게 동작

---

## 성능 기준

### 목표 지표
- [ ] 목록 초기 로딩: 2초 이내
- [ ] 이미지 업로드 (5MB): 10초 이내
- [ ] 실시간 업데이트 반영: 1초 이내
- [ ] 화면 전환 애니메이션: 300ms

### 메모리 사용
- [ ] 목록 화면: 50MB 이하
- [ ] 업로드 화면: 100MB 이하 (이미지 포함)
- [ ] 메모리 누수 없음 (10분 사용 후 확인)

---

## 접근성 기준

- [ ] 모든 버튼에 Semantic Label 추가
- [ ] 스크린 리더로 모든 텍스트 읽기 가능
- [ ] 색상 대비 WCAG AA 기준 준수 (최소 4.5:1)
- [ ] 터치 타겟 크기: 최소 48x48 픽셀

---

## 보안 기준

- [ ] 이미지 URL은 Firebase Storage 보안 규칙 적용
- [ ] 파일 확장자 화이트리스트 검증
- [ ] 사용자 인증 없이는 목록 조회 불가
- [ ] SQL Injection, XSS 등 보안 취약점 없음

---

## 완료 조건 (Definition of Done)

### 필수 조건
- [ ] 모든 인수 시나리오 통과
- [ ] 테스트 커버리지 ≥ 85%
- [ ] `flutter analyze` 경고 0개
- [ ] 모든 파일에 @TAG 포함
- [ ] SPEC 요구사항 100% 구현

### 권장 조건
- [ ] 코드 리뷰 완료
- [ ] 실제 기기에서 테스트 완료 (iOS + Android)
- [ ] 접근성 검증 완료
- [ ] 성능 프로파일링 완료

---

**작성일**: 2025-10-15
**작성자**: @edward
