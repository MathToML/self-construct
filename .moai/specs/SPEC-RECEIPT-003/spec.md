---
id: RECEIPT-003
version: 0.1.0
status: completed
created: 2025-10-16
updated: 2025-10-16
author: @edward
priority: high
category: feature
labels:
  - receipt
  - detail-view
  - crud
  - ui
depends_on:
  - RECEIPT-001
  - RECEIPT-002
scope:
  packages:
    - lib/pages
    - lib/widgets
  files:
    - receipt_detail_page.dart
    - receipt_edit_page.dart
---

# @SPEC:RECEIPT-003: 영수증 상세 보기 및 수정/삭제/제출 기능

## HISTORY

### v0.1.0 (2025-10-16)
- **COMPLETED**: TDD 구현 완료 (RED-GREEN-REFACTOR)
- **AUTHOR**: @edward
- **FEATURES**:
  - 영수증 상세 보기 화면 (ReceiptDetailPage)
  - 수정 기능 (ReceiptUploadPage 재사용)
  - 삭제 기능 (Firebase Storage + Firestore)
  - 제출 기능 (isSubmitted 플래그 업데이트)
  - 조건부 UI 렌더링 (isSubmitted 기반)
  - GoRouter 경로 파라미터 (/receipt/:id, /receipt/:id/edit)
- **TESTS**: Widget 테스트 통과 (4/4)
- **CODE**:
  - lib/pages/receipt_detail_page.dart (506 LOC)
  - lib/models/receipt_record.dart (copyWith 메서드)
  - lib/pages/receipt_upload_page.dart (수정 모드)
  - lib/widgets/receipt_card.dart (클릭 이벤트)
  - lib/main.dart (GoRouter 라우트)
- **COMMITS**:
  - 🔴 RED: d5e2d76
  - 🟢 GREEN: ed7cd56
  - ♻️ REFACTOR: bea21c4

### v0.0.1 (2025-10-16)
- **INITIAL**: 영수증 상세 보기 SPEC 최초 작성
- **AUTHOR**: @edward
- **SCOPE**: 영수증 상세 화면, 수정/삭제/제출 기능
- **CONTEXT**: RECEIPT-002 목록 화면에서 카드 클릭 시 상세 보기 및 CRUD 작업 제공
- **DEPENDENCIES**: RECEIPT-001 (ReceiptRecord 모델), RECEIPT-002 (ReceiptCard, 목록 화면)

---

## 1. Environment (환경 및 전제조건)

### 기술 환경
- **Frontend**: Flutter Web 3.24+
- **UI Framework**: shadcn_ui (ShadCard, ShadButton, ShadDialog 등)
- **Backend**: Firebase Platform
  - **Database**: Cloud Firestore
  - **Storage**: Firebase Storage
  - **Authentication**: Firebase Auth
- **State Management**: StatefulWidget (로컬 상태 관리)
- **Routing**: go_router

### Firebase 프로젝트 구조
```
Firestore Database:
  └── receipts/
      └── {receiptId}
          ├── userId: string
          ├── imageUrl: string
          ├── amount: number
          ├── date: timestamp
          ├── category: string (optional)
          ├── businessPurpose: string (optional)
          ├── createdAt: timestamp
          └── isSubmitted: boolean  ⭐ 핵심 필드
```

### 의존성
- **RECEIPT-001**: ReceiptRecord 모델, Firebase 연동
- **RECEIPT-002**: ReceiptCard 위젯, ReceiptListPage

---

## 2. Assumptions (전제 조건)

### 사용자 인증
- 모든 작업은 인증된 사용자만 수행 가능
- Firestore 보안 규칙: 본인의 영수증만 조회/수정/삭제 가능

### 데이터 정합성
- 영수증 ID는 Firestore 자동 생성 ID 사용
- 제출된 영수증(`isSubmitted: true`)은 수정/삭제 불가
- 삭제 시 Firestore 문서와 Storage 이미지 동시 삭제

### 파일 제약
- 이미지는 Firebase Storage에 저장됨
- Web 플랫폼 호환: Image.memory(), Uint8List 사용

### 보안 가정
- Firestore 보안 규칙: 제출된 영수증(`isSubmitted: true`)은 업데이트/삭제 불가
- Storage 보안 규칙: 본인의 파일만 읽기/쓰기 가능

---

## 3. Requirements (기능 요구사항 - EARS 방식)

### 3.1. Ubiquitous Requirements (기본 요구사항)
- 시스템은 영수증 카드 클릭 시 상세 페이지로 이동하는 기능을 제공해야 한다
- 시스템은 전체 크기 이미지와 모든 정보를 표시하는 상세 화면을 제공해야 한다
- 시스템은 영수증 수정 기능을 제공해야 한다 (제출 전에만)
- 시스템은 영수증 삭제 기능을 제공해야 한다 (제출 전에만)
- 시스템은 영수증 제출 기능을 제공해야 한다 (`isSubmitted: false` → `true`)

### 3.2. Event-driven Requirements (이벤트 기반)
- WHEN 사용자가 ReceiptCard를 탭하면, 시스템은 해당 영수증의 상세 페이지(ReceiptDetailPage)로 이동해야 한다
- WHEN 사용자가 "수정" 버튼을 누르면, 시스템은 수정 화면으로 이동하고 기존 정보를 입력 필드에 채워야 한다
- WHEN 사용자가 "삭제" 버튼을 누르면, 시스템은 확인 다이얼로그를 표시해야 한다
- WHEN 사용자가 삭제를 확인하면, 시스템은 Firestore 문서와 Storage 이미지를 삭제하고 목록 화면으로 복귀해야 한다
- WHEN 사용자가 "제출" 버튼을 누르면, 시스템은 확인 다이얼로그를 표시해야 한다
- WHEN 사용자가 제출을 확인하면, 시스템은 `isSubmitted`를 `true`로 업데이트하고 확인 메시지를 표시해야 한다
- WHEN 수정이 완료되면, 시스템은 Firestore를 업데이트하고 상세 화면으로 복귀해야 한다
- WHEN Firestore 업데이트가 실패하면, 시스템은 에러 메시지를 표시하고 재시도 옵션을 제공해야 한다

### 3.3. State-driven Requirements (상태 기반)
- WHILE 영수증이 제출된 상태(`isSubmitted: true`)일 때, 수정/삭제/제출 버튼은 비활성화되거나 숨겨져야 한다
- WHILE 이미지가 로딩 중일 때, 시스템은 로딩 인디케이터를 표시해야 한다
- WHILE 삭제가 진행 중일 때, 시스템은 삭제 버튼을 비활성화하고 진행 상태를 표시해야 한다
- WHILE 제출이 진행 중일 때, 시스템은 제출 버튼을 비활성화하고 진행 상태를 표시해야 한다

### 3.4. Optional Features (선택적 기능)
- WHERE 영수증 이미지가 PDF 파일이면, 시스템은 PDF 뷰어를 제공할 수 있다
- WHERE 영수증에 OCR 데이터가 있으면, 시스템은 추출된 정보를 별도로 표시할 수 있다

### 3.5. Constraints (제약사항)
- IF 영수증이 이미 제출된 상태(`isSubmitted: true`)이면, 수정/삭제/재제출이 불가능해야 한다
- 삭제 작업은 확인 다이얼로그에서 "삭제" 버튼을 눌러야만 실행되어야 한다
- 제출 작업은 확인 다이얼로그에서 "제출" 버튼을 눌러야만 실행되어야 한다
- Firestore 보안 규칙: `isSubmitted: true`인 문서는 업데이트/삭제 불가
- 네트워크 오류 시 적절한 에러 메시지와 재시도 옵션 제공

---

## 4. Specifications (상세 명세)

### 4.1. ReceiptDetailPage (영수증 상세 화면)

#### 4.1.1 화면 구조
```dart
// @CODE:RECEIPT-003:UI - ReceiptDetailPage
class ReceiptDetailPage extends StatefulWidget {
  final String receiptId;

  const ReceiptDetailPage({required this.receiptId});

  @override
  State<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  // Scaffold
  //   AppBar: "영수증 상세" + 뒤로가기 버튼
  //   Body: SingleChildScrollView
  //     - Full-size Image (CachedNetworkImage)
  //     - Info Card (금액, 날짜, 카테고리, 업무 목적, 제출 상태)
  //   BottomNavigationBar (조건부):
  //     - isSubmitted == false:
  //       - 수정 버튼
  //       - 삭제 버튼
  //       - 제출 버튼
  //     - isSubmitted == true:
  //       - "이미 제출된 영수증입니다" 메시지
}
```

#### 4.1.2 표시 정보
- **이미지**: 전체 크기, CachedNetworkImage, 확대/축소 지원
- **금액**: `NumberFormat.currency(locale: 'ko_KR', symbol: '₩')` 형식
- **날짜**: `yyyy-MM-dd` 형식
- **카테고리**: ShadBadge 위젯
- **업무 목적**: 전체 텍스트 표시 (줄바꿈 지원)
- **제출 상태**:
  - `isSubmitted: true` → 초록색 "제출됨" 배지
  - `isSubmitted: false` → 주황색 "대기중" 배지
- **생성일**: `createdAt` (yyyy-MM-dd HH:mm)

#### 4.1.3 액션 버튼 (조건부 렌더링)

**제출 전 (`isSubmitted: false`)**:
```dart
Row(
  children: [
    Expanded(
      child: ShadButton(
        onPressed: _showEditDialog,
        child: Text('수정'),
      ),
    ),
    SizedBox(width: 8),
    Expanded(
      child: ShadButton.destructive(
        onPressed: _showDeleteDialog,
        child: Text('삭제'),
      ),
    ),
    SizedBox(width: 8),
    Expanded(
      child: ShadButton(
        onPressed: _showSubmitDialog,
        child: Text('제출'),
      ),
    ),
  ],
)
```

**제출 후 (`isSubmitted: true`)**:
```dart
Container(
  padding: EdgeInsets.all(16),
  color: Colors.grey[200],
  child: Row(
    children: [
      Icon(Icons.check_circle, color: Colors.green),
      SizedBox(width: 8),
      Text(
        '이미 제출된 영수증입니다. 수정 및 삭제가 불가능합니다.',
        style: TextStyle(color: Colors.grey[700]),
      ),
    ],
  ),
)
```

### 4.2. 수정 기능 (ReceiptEditPage 또는 Dialog)

#### 4.2.1 접근 방법 (2가지 옵션)

**옵션 1: 수정 전용 페이지**
- `ReceiptEditPage` 생성
- ReceiptUploadPage와 유사한 구조
- 기존 데이터를 컨트롤러에 채워서 표시

**옵션 2: ReceiptUploadPage 재사용** (권장)
- 라우터 파라미터로 `receiptId` 전달
- `receiptId`가 있으면 수정 모드, 없으면 생성 모드
- 초기화 시 기존 데이터 로드

#### 4.2.2 수정 플로우
```
1. "수정" 버튼 탭
   ↓
2. ReceiptUploadPage(receiptId: widget.receiptId) 이동
   ↓
3. Firestore에서 기존 데이터 로드
   ↓
4. 컨트롤러에 기존 값 설정
   ↓
5. 사용자 수정
   ↓
6. "저장" 버튼 탭
   ↓
7. Firestore 업데이트 (UPDATE)
   ↓
8. 상세 화면으로 복귀
```

#### 4.2.3 Firestore 업데이트
```dart
Future<void> _updateReceipt() async {
  try {
    await FirebaseFirestore.instance
        .collection('receipts')
        .doc(widget.receiptId)
        .update({
      'amount': double.parse(_amountController.text),
      'category': _selectedCategory,
      'date': Timestamp.fromDate(_selectedDate),
      'businessPurpose': _businessPurposeController.text.trim(),
      // imageUrl은 변경 시에만 업데이트
      if (_newImageBytes != null) 'imageUrl': _newImageUrl,
    });

    if (mounted) {
      ShadToaster.of(context).show(
        const ShadToast(
          description: Text('영수증이 수정되었습니다'),
        ),
      );
      context.pop(); // 상세 화면으로 복귀
    }
  } catch (e) {
    if (mounted) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text('수정 실패: $e'),
        ),
      );
    }
  }
}
```

### 4.3. 삭제 기능

#### 4.3.1 삭제 확인 다이얼로그
```dart
Future<void> _showDeleteDialog() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => ShadDialog(
      title: const Text('영수증 삭제'),
      description: const Text(
        '정말로 이 영수증을 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.',
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        ShadButton.destructive(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('삭제'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await _deleteReceipt();
  }
}
```

#### 4.3.2 삭제 플로우
```
1. "삭제" 버튼 탭
   ↓
2. 확인 다이얼로그 표시
   ↓
3. "삭제" 확인
   ↓
4. Firestore 문서 삭제
   ↓
5. Storage 이미지 삭제
   ↓
6. 목록 화면으로 복귀
```

#### 4.3.3 Firestore + Storage 삭제
```dart
Future<void> _deleteReceipt() async {
  setState(() => _isDeleting = true);

  try {
    // 1. Storage 이미지 삭제
    final imageUrl = _receipt.imageUrl;
    if (imageUrl.isNotEmpty) {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    }

    // 2. Firestore 문서 삭제
    await FirebaseFirestore.instance
        .collection('receipts')
        .doc(widget.receiptId)
        .delete();

    if (mounted) {
      ShadToaster.of(context).show(
        const ShadToast(
          description: Text('영수증이 삭제되었습니다'),
        ),
      );
      context.go('/'); // 목록 화면으로 복귀
    }
  } on FirebaseException catch (e) {
    if (mounted) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text('삭제 실패: ${e.message}'),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isDeleting = false);
    }
  }
}
```

### 4.4. 제출 기능

#### 4.4.1 제출 확인 다이얼로그
```dart
Future<void> _showSubmitDialog() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => ShadDialog(
      title: const Text('영수증 제출'),
      description: const Text(
        '영수증을 제출하시겠습니까? 제출 후에는 수정 및 삭제가 불가능합니다.',
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        ShadButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('제출'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await _submitReceipt();
  }
}
```

#### 4.4.2 제출 플로우
```
1. "제출" 버튼 탭
   ↓
2. 확인 다이얼로그 표시
   ↓
3. "제출" 확인
   ↓
4. Firestore isSubmitted: true 업데이트
   ↓
5. 확인 메시지 표시
   ↓
6. 버튼 상태 업데이트 (비활성화)
```

#### 4.4.3 Firestore 업데이트
```dart
Future<void> _submitReceipt() async {
  setState(() => _isSubmitting = true);

  try {
    await FirebaseFirestore.instance
        .collection('receipts')
        .doc(widget.receiptId)
        .update({
      'isSubmitted': true,
    });

    setState(() {
      _receipt = _receipt.copyWith(isSubmitted: true);
    });

    if (mounted) {
      ShadToaster.of(context).show(
        const ShadToast(
          description: Text('영수증이 제출되었습니다'),
        ),
      );
    }
  } on FirebaseException catch (e) {
    if (mounted) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text('제출 실패: ${e.message}'),
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}
```

### 4.5. 라우팅 설정 (go_router)

```dart
// lib/main.dart or lib/router.dart
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ReceiptListPage(),
    ),
    GoRoute(
      path: '/upload',
      builder: (context, state) => const ReceiptUploadPage(),
    ),
    GoRoute(
      path: '/receipt/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ReceiptDetailPage(receiptId: id);
      },
    ),
    GoRoute(
      path: '/receipt/:id/edit',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ReceiptUploadPage(receiptId: id); // 수정 모드
      },
    ),
  ],
);
```

### 4.6. ReceiptCard 업데이트 (클릭 이벤트)

```dart
// lib/widgets/receipt_card.dart
class ReceiptCard extends StatelessWidget {
  final ReceiptRecord receipt;

  const ReceiptCard({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 상세 페이지로 이동
        context.push('/receipt/${receipt.id}');
      },
      child: ShadCard(
        // ... 기존 카드 UI
      ),
    );
  }
}
```

---

## 5. Traceability (@TAG 추적성)

### TAG 체인
```
@SPEC:RECEIPT-003
  ↓
@TEST:RECEIPT-003
  - test/pages/receipt_detail_page_test.dart
  - test/pages/receipt_edit_page_test.dart (선택)
  - test/integration/receipt_crud_test.dart
  ↓
@CODE:RECEIPT-003
  - lib/pages/receipt_detail_page.dart
  - lib/pages/receipt_upload_page.dart (수정 모드 추가)
  - lib/widgets/receipt_card.dart (onTap 추가)
  ↓
@DOC:RECEIPT-003
  - docs/user-guide/receipt-detail.md
```

### 코드 내 TAG 예시

**lib/pages/receipt_detail_page.dart**:
```dart
// @CODE:RECEIPT-003:UI | SPEC: .moai/specs/SPEC-RECEIPT-003/spec.md | TEST: test/pages/receipt_detail_page_test.dart
class ReceiptDetailPage extends StatefulWidget {
  // 영수증 상세 보기 화면 구현
}
```

**test/pages/receipt_detail_page_test.dart**:
```dart
// @TEST:RECEIPT-003 | SPEC: .moai/specs/SPEC-RECEIPT-003/spec.md
void main() {
  group('ReceiptDetailPage Tests', () {
    // Widget 테스트
  });
}
```

---

## 6. Non-Functional Requirements (비기능 요구사항)

### 성능
- 상세 화면 로딩 시간: 1초 이내
- 이미지 로딩: 3MB 기준 3초 이내
- Firestore 업데이트 응답: 500ms 이내

### 보안
- Firestore 보안 규칙: 제출된 영수증은 업데이트/삭제 불가
- 사용자 인증 필수 (GoRouter redirect)
- Storage 보안 규칙: 본인의 파일만 삭제 가능

### 사용성
- 삭제/제출 시 명확한 확인 다이얼로그
- 에러 메시지는 ShadToast로 3초간 표시
- 로딩 상태는 CircularProgressIndicator로 표시

### 접근성
- 모든 버튼에 Semantic Label 추가
- 색상 대비 WCAG AA 기준 준수
- 스크린 리더 지원

---

## 7. 구현 우선순위

### Phase 1: Core 기능 (이번 SPEC 범위)
1. ReceiptDetailPage 기본 구조
2. 전체 크기 이미지 표시
3. 모든 정보 표시 (금액, 날짜, 카테고리, 상태 등)
4. 수정 기능 (ReceiptUploadPage 재사용)
5. 삭제 기능 (Firestore + Storage)
6. 제출 기능 (`isSubmitted` 업데이트)

### Phase 2: 추후 확장
- PDF 뷰어 (이미지가 PDF인 경우)
- OCR 데이터 표시 (추출된 정보)
- 이미지 확대/축소 (Pinch-to-Zoom)
- 영수증 공유 기능

---

## 8. 참고 자료

### Firebase 공식 문서
- [Firestore Update Data](https://firebase.google.com/docs/firestore/manage-data/add-data#update-data)
- [Storage Delete Files](https://firebase.google.com/docs/storage/web/delete-files)

### go_router
- [Named Routes](https://pub.dev/documentation/go_router/latest/topics/Named%20routes-topic.html)
- [Path Parameters](https://pub.dev/documentation/go_router/latest/topics/Get%20started-topic.html#adding-a-second-route)

### shadcn_ui
- [ShadDialog](https://flutter-shadcn-ui.mariuti.com/docs/components/dialog)
- [ShadToast](https://flutter-shadcn-ui.mariuti.com/docs/components/toast)

---

**다음 단계**: `/alfred:2-build SPEC-RECEIPT-003` 실행하여 TDD 구현 시작
