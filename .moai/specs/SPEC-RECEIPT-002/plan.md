# SPEC-RECEIPT-002 구현 계획

> **TDD 기반 영수증 UI 구현 계획**

---

## 개요

- **SPEC ID**: RECEIPT-002
- **목표**: Flutter 기반 영수증 실시간 목록 조회 및 상세 업로드 기능 구현
- **방법론**: RED → GREEN → REFACTOR (TDD)
- **우선순위**: High
- **의존성**: RECEIPT-001 (Receipt 모델, ReceiptService) 완료 필수

---

## 1단계: RED - 실패하는 테스트 작성

### 1.1 ReceiptListPage 테스트

**파일**: `test/pages/receipt_list_page_test.dart`

```dart
// @TEST:RECEIPT-002 | SPEC: .moai/specs/SPEC-RECEIPT-002/spec.md

void main() {
  group('ReceiptListPage Tests', () {
    testWidgets('로딩 상태에서 CircularProgressIndicator 표시', (tester) async {
      // Given: Stream이 아직 데이터를 방출하지 않음
      // When: ReceiptListPage 렌더링
      // Then: CircularProgressIndicator가 표시되어야 함
    });

    testWidgets('빈 목록일 때 EmptyStateWidget 표시', (tester) async {
      // Given: 빈 영수증 목록
      // When: ReceiptListPage 렌더링
      // Then: "등록된 영수증이 없습니다" 메시지 표시
    });

    testWidgets('영수증 목록이 최신순으로 정렬되어 표시', (tester) async {
      // Given: 3개의 영수증 (date 다름)
      // When: ReceiptListPage 렌더링
      // Then: date 내림차순으로 정렬된 목록 표시
    });

    testWidgets('FloatingActionButton 클릭 시 업로드 화면 이동', (tester) async {
      // Given: ReceiptListPage 렌더링
      // When: FAB 클릭
      // Then: ReceiptUploadPage로 네비게이션
    });

    testWidgets('네트워크 에러 시 ErrorWidget 표시', (tester) async {
      // Given: Stream에서 에러 방출
      // When: ReceiptListPage 렌더링
      // Then: ErrorWidget 표시
    });
  });
}
```

### 1.2 ReceiptUploadPage 테스트

**파일**: `test/pages/receipt_upload_page_test.dart`

```dart
// @TEST:RECEIPT-002 | SPEC: .moai/specs/SPEC-RECEIPT-002/spec.md

void main() {
  group('ReceiptUploadPage Tests', () {
    testWidgets('이미지 선택 버튼 클릭 시 FilePicker 실행', (tester) async {
      // Given: ReceiptUploadPage 렌더링
      // When: "이미지 선택" 버튼 클릭
      // Then: FilePicker 실행
    });

    testWidgets('5MB 초과 파일 선택 시 에러 메시지 표시', (tester) async {
      // Given: 6MB 파일 선택
      // When: pickImage() 실행
      // Then: "파일 크기는 5MB를 초과할 수 없습니다" SnackBar 표시
    });

    testWidgets('필수 필드 누락 시 업로드 차단', (tester) async {
      // Given: storeName만 입력, totalAmount 누락
      // When: "업로드" 버튼 클릭
      // Then: 유효성 검증 실패, 에러 메시지 표시
    });

    testWidgets('업로드 성공 시 목록 화면 복귀', (tester) async {
      // Given: 모든 필드 입력 완료
      // When: "업로드" 버튼 클릭
      // Then: receiptService.uploadReceipt() 호출 → Navigator.pop()
    });

    testWidgets('업로드 중 버튼 비활성화 및 진행률 표시', (tester) async {
      // Given: 업로드 진행 중
      // When: isUploading == true
      // Then: 업로드 버튼 비활성화, CircularProgressIndicator 표시
    });
  });
}
```

### 1.3 ReceiptCard 테스트

**파일**: `test/widgets/receipt_card_test.dart`

```dart
// @TEST:RECEIPT-002 | SPEC: .moai/specs/SPEC-RECEIPT-002/spec.md

void main() {
  group('ReceiptCard Tests', () {
    testWidgets('영수증 정보가 올바르게 표시', (tester) async {
      // Given: Receipt 객체
      // When: ReceiptCard 렌더링
      // Then: storeName, totalAmount, date, category 표시 확인
    });

    testWidgets('storeName이 20자 초과 시 생략', (tester) async {
      // Given: storeName이 30자인 Receipt
      // When: ReceiptCard 렌더링
      // Then: "..." 생략 표시 확인
    });

    testWidgets('totalAmount가 통화 형식으로 표시', (tester) async {
      // Given: totalAmount = 12345.67
      // When: ReceiptCard 렌더링
      // Then: "₩12,346" 형식 표시
    });

    testWidgets('이미지 썸네일이 80x80으로 표시', (tester) async {
      // Given: imageUrl 포함 Receipt
      // When: ReceiptCard 렌더링
      // Then: Image.network 위젯 크기 80x80 확인
    });
  });
}
```

### 1.4 테스트 실행 및 실패 확인

```bash
flutter test test/pages/receipt_list_page_test.dart
flutter test test/pages/receipt_upload_page_test.dart
flutter test test/widgets/receipt_card_test.dart

# 예상 결과: 모든 테스트 FAIL (구현 전)
```

---

## 2단계: GREEN - 최소 구현

### 2.1 ReceiptListPage 구현

**파일**: `lib/presentation/pages/receipt_list_page.dart`

```dart
// @CODE:RECEIPT-002:UI | SPEC: .moai/specs/SPEC-RECEIPT-002/spec.md | TEST: test/pages/receipt_list_page_test.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReceiptListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final receiptService = Provider.of<ReceiptService>(context);
    final userId = getCurrentUserId(); // 인증 서비스에서 가져오기

    return Scaffold(
      appBar: AppBar(title: Text('영수증 목록')),
      body: StreamBuilder<List<Receipt>>(
        stream: receiptService.watchReceipts(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('에러: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('등록된 영수증이 없습니다'));
          }

          final receipts = snapshot.data!;
          receipts.sort((a, b) => b.date.compareTo(a.date)); // 최신순 정렬

          return ListView.builder(
            itemCount: receipts.length,
            itemBuilder: (context, index) {
              return ReceiptCard(receipt: receipts[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReceiptUploadPage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### 2.2 ReceiptUploadPage 구현

**파일**: `lib/presentation/pages/receipt_upload_page.dart`

```dart
// @CODE:RECEIPT-002:UI | SPEC: .moai/specs/SPEC-RECEIPT-002/spec.md | TEST: test/pages/receipt_upload_page_test.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ReceiptUploadPage extends StatefulWidget {
  @override
  _ReceiptUploadPageState createState() => _ReceiptUploadPageState();
}

class _ReceiptUploadPageState extends State<ReceiptUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final storeNameController = TextEditingController();
  final totalAmountController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  String selectedCategory = '기타';
  File? imageFile;
  bool isUploading = false;

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowedExtensions: ['jpg', 'png'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final size = await file.length();

      if (size > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 크기는 5MB를 초과할 수 없습니다')),
        );
        return;
      }

      setState(() => imageFile = file);
    }
  }

  Future<void> uploadReceipt() async {
    if (!_formKey.currentState!.validate()) return;
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지를 선택해주세요')),
      );
      return;
    }

    setState(() => isUploading = true);

    try {
      final receipt = Receipt(
        id: generateId(),
        userId: getCurrentUserId(),
        storeName: storeNameController.text,
        totalAmount: double.parse(totalAmountController.text),
        date: selectedDate,
        category: selectedCategory,
        createdAt: DateTime.now(),
      );

      await receiptService.uploadReceipt(receipt, imageFile!);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패: $e')),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('영수증 업로드')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: storeNameController,
              decoration: InputDecoration(labelText: '상호명*'),
              maxLength: 50,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '상호명을 입력해주세요';
                }
                return null;
              },
            ),
            TextFormField(
              controller: totalAmountController,
              decoration: InputDecoration(labelText: '금액*'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '금액을 입력해주세요';
                }
                if (double.tryParse(value) == null) {
                  return '올바른 금액을 입력해주세요';
                }
                return null;
              },
            ),
            // 날짜 선택, 카테고리 선택, 이미지 선택 버튼 등 추가...
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isUploading ? null : uploadReceipt,
              child: isUploading
                  ? CircularProgressIndicator()
                  : Text('업로드'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 2.3 ReceiptCard 구현

**파일**: `lib/presentation/widgets/receipt_card.dart`

```dart
// @CODE:RECEIPT-002:UI | SPEC: .moai/specs/SPEC-RECEIPT-002/spec.md | TEST: test/widgets/receipt_card_test.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReceiptCard extends StatelessWidget {
  final Receipt receipt;

  ReceiptCard({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');
    final dateFormat = DateFormat('yyyy-MM-dd');

    String displayStoreName = receipt.storeName;
    if (displayStoreName.length > 20) {
      displayStoreName = displayStoreName.substring(0, 20) + '...';
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: receipt.imageUrl != null
            ? Image.network(
                receipt.imageUrl!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              )
            : Container(width: 80, height: 80, color: Colors.grey[300]),
        title: Text(
          displayStoreName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currencyFormat.format(receipt.totalAmount),
              style: TextStyle(fontSize: 18, color: Theme.of(context).primaryColor),
            ),
            Text(
              dateFormat.format(receipt.date),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Chip(label: Text(receipt.category)),
          ],
        ),
      ),
    );
  }
}
```

### 2.4 테스트 재실행 및 통과 확인

```bash
flutter test

# 예상 결과: 모든 테스트 PASS
```

---

## 3단계: REFACTOR - 코드 품질 개선

### 3.1 에러 처리 강화

- **NetworkException**: 네트워크 오류 시 재시도 버튼 제공
- **ValidationException**: 상세한 유효성 검증 에러 메시지
- **StorageException**: 업로드 실패 시 로컬 저장 옵션

### 3.2 사용성 개선

- **Pull-to-Refresh**: 목록 화면에 새로고침 제스처 추가
- **Shimmer Loading**: 로딩 중 스켈레톤 UI 표시
- **Image Compression**: 업로드 전 이미지 자동 압축

### 3.3 @TAG 추적성 추가

모든 파일 상단에 TAG BLOCK 추가:

```dart
// @CODE:RECEIPT-002:UI | SPEC: .moai/specs/SPEC-RECEIPT-002/spec.md | TEST: test/pages/receipt_list_page_test.dart
```

### 3.4 주석 및 문서화

- 각 클래스/함수에 DartDoc 주석 추가
- SPEC 요구사항 참조 주석 추가
- 복잡한 로직에 설명 주석 추가

### 3.5 성능 최적화

- `ListView.builder` 사용 (이미 적용)
- 이미지 캐싱 (`cached_network_image` 패키지)
- StreamBuilder 효율화 (불필요한 리빌드 방지)

---

## 검증 체크리스트

### 기능 검증
- [ ] 영수증 목록이 실시간으로 업데이트되는가?
- [ ] 빈 목록일 때 적절한 메시지가 표시되는가?
- [ ] 이미지 선택 및 미리보기가 정상 동작하는가?
- [ ] 5MB 초과 파일이 차단되는가?
- [ ] 필수 필드 누락 시 업로드가 차단되는가?
- [ ] 업로드 완료 후 목록 화면으로 복귀하는가?

### 품질 검증
- [ ] 모든 테스트가 통과하는가?
- [ ] 테스트 커버리지가 85% 이상인가?
- [ ] `flutter analyze` 경고가 없는가?
- [ ] 모든 파일에 @TAG가 포함되어 있는가?
- [ ] SPEC 요구사항이 100% 구현되었는가?

### 비기능 검증
- [ ] 목록 초기 로딩이 2초 이내인가?
- [ ] 업로드 진행률이 표시되는가?
- [ ] 에러 메시지가 명확한가?
- [ ] 접근성 레이블이 추가되었는가?

---

## 다음 단계

1. **TDD 구현 완료**: `/alfred:2-build SPEC-RECEIPT-002` 실행
2. **문서 동기화**: `/alfred:3-sync` 실행
3. **RECEIPT-003 SPEC 작성**: 상세 화면, 수정/삭제 기능
4. **통합 테스트**: RECEIPT-001 + RECEIPT-002 연동 확인

---

**작성일**: 2025-10-15
**작성자**: @edward
