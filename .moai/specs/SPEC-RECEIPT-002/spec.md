---
id: RECEIPT-002
version: 0.0.1
status: draft
created: 2025-10-15
updated: 2025-10-15
author: @edward
priority: high
category: feature
labels:
  - receipt
  - ui
  - realtime
  - upload
depends_on:
  - RECEIPT-001
scope:
  packages:
    - lib/presentation/pages
    - lib/presentation/widgets
  files:
    - receipt_list_page.dart
    - receipt_upload_page.dart
    - receipt_card.dart
---

# @SPEC:RECEIPT-002: 영수증 실시간 목록 조회 및 상세 업로드 기능

## HISTORY

### v0.0.1 (2025-10-15)
- **INITIAL**: 영수증 실시간 목록 조회 및 상세 업로드 기능 SPEC 작성
- **AUTHOR**: @edward
- **REASON**: Flutter UI 레이어 구현, RECEIPT-001 기반 화면 구성

---

## Environment (환경 및 가정사항)

### 실행 환경
- Flutter SDK 3.24.5 이상
- Dart 3.5.4 이상
- iOS 12.0+ / Android 7.0+

### 기술 스택
- **State Management**: Provider 패턴 (RECEIPT-001 의존)
- **UI Framework**: Flutter Material Design
- **Realtime Database**: Firebase Realtime Database (StreamBuilder 활용)
- **File Picker**: file_picker 패키지
- **Image Handling**: image_picker, image 패키지

### 외부 의존성
- RECEIPT-001: Receipt 모델, ReceiptService, ReceiptRepository 구현 완료 필수
- Firebase Realtime Database 연결 완료
- 파일 업로드 Storage 준비 완료

---

## Assumptions (전제 조건)

1. **RECEIPT-001 완료**: Receipt 모델 및 ReceiptService가 정상 동작
2. **Firebase 설정**: Realtime Database, Storage 권한 설정 완료
3. **파일 접근 권한**: iOS Info.plist, Android Manifest 파일 접근 권한 선언 완료
4. **네트워크 연결**: 모든 기능은 네트워크 연결 상태에서 동작
5. **사용자 인증**: 로그인된 사용자만 영수증 조회/업로드 가능

---

## Requirements (기능 요구사항)

### Ubiquitous Requirements (기본 요구사항)
- 시스템은 사용자의 영수증 목록을 실시간으로 조회하는 화면을 제공해야 한다
- 시스템은 영수증 이미지를 업로드하는 화면을 제공해야 한다
- 시스템은 영수증 목록에서 각 영수증을 카드 형식으로 표시해야 한다
- 시스템은 업로드 중 진행 상황을 시각적으로 표시해야 한다

### Event-driven Requirements (이벤트 기반)
- WHEN 사용자가 영수증 목록 화면에 진입하면, 시스템은 StreamBuilder를 통해 실시간 영수증 목록을 표시해야 한다
- WHEN Firebase에서 영수증이 추가/수정/삭제되면, 시스템은 자동으로 UI를 업데이트해야 한다
- WHEN 사용자가 "영수증 업로드" 버튼을 누르면, 시스템은 업로드 화면으로 이동해야 한다
- WHEN 사용자가 "이미지 선택" 버튼을 누르면, 시스템은 파일 선택기를 실행해야 한다
- WHEN 사용자가 이미지를 선택하면, 시스템은 미리보기를 표시해야 한다
- WHEN 사용자가 "업로드" 버튼을 누르면, 시스템은 유효성 검증 후 Firebase에 업로드해야 한다
- WHEN 업로드가 완료되면, 시스템은 목록 화면으로 자동 복귀해야 한다
- WHEN 네트워크 오류가 발생하면, 시스템은 명확한 에러 메시지를 표시해야 한다

### State-driven Requirements (상태 기반)
- WHILE 영수증 목록이 로딩 중일 때, 시스템은 로딩 인디케이터를 표시해야 한다
- WHILE 영수증 목록이 비어있을 때, 시스템은 "등록된 영수증이 없습니다" 메시지를 표시해야 한다
- WHILE 업로드가 진행 중일 때, 시스템은 업로드 버튼을 비활성화하고 진행률을 표시해야 한다
- WHILE 이미지가 선택되지 않았을 때, 시스템은 업로드 버튼을 비활성화해야 한다

### Constraints (제약사항)
- IF 업로드 파일 크기가 5MB를 초과하면, 시스템은 업로드를 거부하고 에러 메시지를 표시해야 한다
- IF 지원하지 않는 파일 형식(jpg, png 외)이 선택되면, 시스템은 선택을 거부해야 한다
- IF 필수 필드(storeName, totalAmount, date)가 누락되면, 시스템은 업로드를 차단하고 사용자에게 알려야 한다
- 영수증 카드는 최대 3줄까지만 표시하고 나머지는 생략(...)해야 한다
- 목록은 최신순(date 기준 내림차순)으로 정렬되어야 한다

---

## Specifications (상세 명세)

### 1. ReceiptListPage (영수증 목록 화면)

#### 1.1 화면 구조
```dart
// @CODE:RECEIPT-002:UI - ReceiptListPage
class ReceiptListPage extends StatelessWidget {
  // StreamBuilder를 통한 실시간 목록 조회
  // AppBar: "영수증 목록" + 업로드 버튼 (FAB)
  // Body: StreamBuilder<List<Receipt>>
  //   - loading: CircularProgressIndicator
  //   - empty: EmptyStateWidget("등록된 영수증이 없습니다")
  //   - data: ListView.builder + ReceiptCard
  //   - error: ErrorWidget
}
```

#### 1.2 주요 기능
- **실시간 조회**: `receiptService.watchReceipts(userId)`로 Stream 구독
- **정렬**: date 기준 내림차순
- **카드 레이아웃**: ReceiptCard 위젯 사용
- **네비게이션**: FloatingActionButton → ReceiptUploadPage

#### 1.3 상태 처리
```dart
StreamBuilder<List<Receipt>>(
  stream: receiptService.watchReceipts(userId),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return ErrorWidget(snapshot.error.toString());
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return EmptyStateWidget();
    }
    return ListView.builder(...);
  }
)
```

### 2. ReceiptUploadPage (영수증 업로드 화면)

#### 2.1 화면 구조
```dart
// @CODE:RECEIPT-002:UI - ReceiptUploadPage
class ReceiptUploadPage extends StatefulWidget {
  // Form + TextFields + ImagePicker
  // Fields: storeName, totalAmount, date, category, imageFile
  // Actions: 이미지 선택, 업로드, 취소
}
```

#### 2.2 입력 필드
- **storeName** (필수): TextField, 최대 50자
- **totalAmount** (필수): TextField, 숫자 입력 키패드, 정규식 검증
- **date** (필수): DatePicker, 기본값 오늘 날짜
- **category** (선택): DropdownButton, 기본값 "기타"
- **imageFile** (필수): FilePicker, jpg/png만 허용

#### 2.3 업로드 플로우
```dart
// 1. 이미지 선택
Future<void> pickImage() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowedExtensions: ['jpg', 'png'],
  );
  if (result != null) {
    final file = File(result.files.single.path!);
    final size = await file.length();
    if (size > 5 * 1024 * 1024) {
      // 5MB 초과 에러
      showError("파일 크기는 5MB를 초과할 수 없습니다");
      return;
    }
    setState(() => imageFile = file);
  }
}

// 2. 업로드 실행
Future<void> uploadReceipt() async {
  if (!_formKey.currentState!.validate()) return;
  if (imageFile == null) {
    showError("이미지를 선택해주세요");
    return;
  }

  setState(() => isUploading = true);

  try {
    final receipt = Receipt(
      id: generateId(),
      userId: currentUserId,
      storeName: storeNameController.text,
      totalAmount: double.parse(totalAmountController.text),
      date: selectedDate,
      category: selectedCategory,
      createdAt: DateTime.now(),
    );

    await receiptService.uploadReceipt(receipt, imageFile!);
    Navigator.pop(context); // 업로드 완료 후 목록 화면 복귀
  } catch (e) {
    showError("업로드 실패: ${e.toString()}");
  } finally {
    setState(() => isUploading = false);
  }
}
```

#### 2.4 유효성 검증
- storeName: 1~50자, 공백만 허용 안 함
- totalAmount: 양수, 최대 10자리
- date: 미래 날짜 불가
- imageFile: jpg/png, 5MB 이하

### 3. ReceiptCard (영수증 카드 위젯)

#### 3.1 카드 레이아웃
```dart
// @CODE:RECEIPT-002:UI - ReceiptCard
class ReceiptCard extends StatelessWidget {
  final Receipt receipt;

  // Card
  //   Row
  //     - Leading: Image.network (thumbnail, 80x80)
  //     - Column
  //       - storeName (bold, 16pt, 1줄)
  //       - totalAmount (18pt, primary color, 1줄)
  //       - date (12pt, grey, 1줄)
  //       - category (chip)
}
```

#### 3.2 표시 형식
- **storeName**: 최대 20자, 초과 시 "..." 생략
- **totalAmount**: `NumberFormat.currency(locale: 'ko_KR', symbol: '₩')`
- **date**: `yyyy-MM-dd` 형식
- **category**: Chip 위젯, 색상 구분

#### 3.3 상호작용
- **onTap**: 상세 화면으로 이동 (RECEIPT-003에서 구현 예정)
- **onLongPress**: 삭제 확인 다이얼로그 (RECEIPT-003에서 구현 예정)

---

## Traceability (추적성)

### TAG 체인
```
@SPEC:RECEIPT-002 (본 문서)
  ↓
@TEST:RECEIPT-002 (test/pages/receipt_list_page_test.dart)
@TEST:RECEIPT-002 (test/pages/receipt_upload_page_test.dart)
@TEST:RECEIPT-002 (test/widgets/receipt_card_test.dart)
  ↓
@CODE:RECEIPT-002:UI (lib/presentation/pages/receipt_list_page.dart)
@CODE:RECEIPT-002:UI (lib/presentation/pages/receipt_upload_page.dart)
@CODE:RECEIPT-002:UI (lib/presentation/widgets/receipt_card.dart)
  ↓
@DOC:RECEIPT-002 (docs/features/receipt-ui.md)
```

### 의존성
- **RECEIPT-001**: Receipt 모델, ReceiptService, ReceiptRepository
- **RECEIPT-003** (예정): 상세 화면, 수정/삭제 기능

---

## Non-Functional Requirements (비기능 요구사항)

### 성능
- 영수증 목록 초기 로딩: 2초 이내
- 이미지 업로드: 5MB 기준 10초 이내
- 실시간 업데이트 반영: 1초 이내

### 사용성
- 로딩 인디케이터는 0.3초 이상 작업 시 표시
- 에러 메시지는 SnackBar로 3초간 표시
- 업로드 완료 시 성공 메시지 표시

### 보안
- 이미지 URL은 Firebase Storage 보안 규칙 적용
- 사용자 인증 없이는 목록 조회 불가
- 파일 확장자 화이트리스트 검증

### 접근성
- 모든 버튼에 Semantic Label 추가
- 색상 대비 WCAG AA 기준 준수
- 스크린 리더 지원

---

## 다음 단계

1. `/alfred:2-build SPEC-RECEIPT-002` 실행 → TDD 구현
2. `/alfred:3-sync` 실행 → Living Document 동기화
3. RECEIPT-003 SPEC 작성 → 상세 화면, 수정/삭제 기능
