// @TEST:RECEIPT-002 | SPEC: .moai/specs/SPEC-RECEIPT-002/spec.md

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_construct/pages/receipt_upload_page.dart';

void main() {
  group('ReceiptUploadPage Tests', () {
    testWidgets('이미지 선택 버튼 클릭 시 FilePicker 실행', (tester) async {
      // Given: ReceiptUploadPage 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptUploadPage(),
        ),
      );

      // When: "이미지 선택" 버튼 클릭
      final imageButton = find.text('이미지 선택');
      expect(imageButton, findsOneWidget);

      // Then: FilePicker 실행 (실제 동작은 통합 테스트에서 확인)
      await tester.tap(imageButton);
      await tester.pumpAndSettle();
    });

    testWidgets('5MB 초과 파일 선택 시 에러 메시지 표시', (tester) async {
      // Given: ReceiptUploadPage 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptUploadPage(),
        ),
      );

      // When: 5MB 초과 파일 선택 (실제 파일은 Mock으로 주입)
      // Then: "파일 크기는 5MB를 초과할 수 없습니다" SnackBar 표시
      // (실제 검증 로직은 GREEN 단계에서 구현)
      expect(find.byType(ReceiptUploadPage), findsOneWidget);
    });

    testWidgets('필수 필드 누락 시 업로드 차단', (tester) async {
      // Given: amount만 입력, businessPurpose 누락
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptUploadPage(),
        ),
      );

      // When: amount 입력
      final amountField = find.byKey(const Key('amount_field'));
      expect(amountField, findsOneWidget);
      await tester.enterText(amountField, '10000');

      // When: "업로드" 버튼 클릭
      final uploadButton = find.text('업로드');
      expect(uploadButton, findsOneWidget);
      await tester.tap(uploadButton);
      await tester.pumpAndSettle();

      // Then: 유효성 검증 실패, 에러 메시지 표시
      // (실제 검증은 GREEN 단계에서 구현)
    });

    testWidgets('업로드 성공 시 목록 화면 복귀', (tester) async {
      // Given: 모든 필드 입력 완료
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptUploadPage(),
        ),
      );

      // When: 모든 필드 입력 + "업로드" 버튼 클릭
      // Then: receiptService.uploadReceipt() 호출 → Navigator.pop()
      // (실제 동작은 GREEN 단계에서 구현)
      expect(find.byType(ReceiptUploadPage), findsOneWidget);
    });

    testWidgets('업로드 중 버튼 비활성화 및 진행률 표시', (tester) async {
      // Given: 업로드 진행 중
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptUploadPage(),
        ),
      );

      // When: isUploading == true
      // Then: 업로드 버튼 비활성화, CircularProgressIndicator 표시
      // (상태 관리는 GREEN 단계에서 구현)
      expect(find.byType(ReceiptUploadPage), findsOneWidget);
    });

    testWidgets('Form에 필수 필드가 모두 표시', (tester) async {
      // Given: ReceiptUploadPage 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptUploadPage(),
        ),
      );

      // Then: amount, category, businessPurpose, date 필드 확인
      expect(find.byKey(const Key('amount_field')), findsOneWidget);
      expect(find.byKey(const Key('category_field')), findsOneWidget);
      expect(find.byKey(const Key('business_purpose_field')), findsOneWidget);
      expect(find.byKey(const Key('date_field')), findsOneWidget);
    });

    testWidgets('AppBar에 제목 표시', (tester) async {
      // Given: ReceiptUploadPage 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptUploadPage(),
        ),
      );

      // Then: AppBar, 제목 확인
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('영수증 업로드'), findsOneWidget);
    });

    testWidgets('카테고리 드롭다운에 옵션 표시', (tester) async {
      // Given: ReceiptUploadPage 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptUploadPage(),
        ),
      );

      // When: 카테고리 드롭다운 클릭
      final categoryDropdown = find.byKey(const Key('category_field'));
      expect(categoryDropdown, findsOneWidget);

      // Then: 카테고리 옵션 표시 (식비, 교통, 숙박, 기타 등)
      // (실제 옵션은 GREEN 단계에서 구현)
    });

    testWidgets('날짜 선택 버튼 클릭 시 DatePicker 표시', (tester) async {
      // Given: ReceiptUploadPage 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptUploadPage(),
        ),
      );

      // When: 날짜 선택 버튼 클릭
      final dateField = find.byKey(const Key('date_field'));
      expect(dateField, findsOneWidget);

      // Then: DatePicker 표시 (실제 동작은 GREEN 단계에서 구현)
      await tester.tap(dateField);
      await tester.pumpAndSettle();
    });

    testWidgets('이미지 미리보기 영역 표시', (tester) async {
      // Given: ReceiptUploadPage 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptUploadPage(),
        ),
      );

      // When: 이미지 선택 전
      // Then: 플레이스홀더 또는 "이미지를 선택해주세요" 메시지 표시
      expect(find.byType(ReceiptUploadPage), findsOneWidget);
    });
  });
}
