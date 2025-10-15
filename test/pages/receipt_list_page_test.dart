// @TEST:RECEIPT-001 | SPEC: .moai/specs/SPEC-RECEIPT-001/spec.md

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_construct/pages/receipt_list_page.dart';

void main() {
  group('ReceiptListPage', () {
    testWidgets('should render basic UI components', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptListPage(),
        ),
      );

      // Assert: 기본 UI 요소가 있는지 확인
      expect(find.byType(ReceiptListPage), findsOneWidget);
    });

    testWidgets('should have floating action button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptListPage(),
        ),
      );

      // Assert: FAB가 있는지 확인
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should display app bar title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptListPage(),
        ),
      );

      // Assert: AppBar가 있는지 확인
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
