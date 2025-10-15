// @TEST:RECEIPT-001 | SPEC: .moai/specs/SPEC-RECEIPT-001/spec.md

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_construct/pages/receipt_upload_page.dart';

void main() {
  group('ReceiptUploadPage', () {
    testWidgets('should render basic UI components', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptUploadPage(),
        ),
      );

      // Assert: 기본 UI 요소가 있는지 확인
      expect(find.byType(ReceiptUploadPage), findsOneWidget);
    });

    testWidgets('should have image upload button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptUploadPage(),
        ),
      );

      // Assert: 업로드 버튼이 있는지 확인
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('should have text fields for amount and category', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptUploadPage(),
        ),
      );

      // Assert: 입력 필드가 있는지 확인
      expect(find.byType(TextField), findsWidgets);
    });
  });
}
