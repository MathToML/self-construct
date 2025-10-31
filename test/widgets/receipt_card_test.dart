// @TEST:RECEIPT-002 | SPEC: .moai/specs/SPEC-RECEIPT-002/spec.md

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_construct/models/receipt_record.dart';
import 'package:self_construct/widgets/receipt_card.dart';

void main() {
  group('ReceiptCard Tests', () {
    late ReceiptRecord testReceipt;

    setUp(() {
      testReceipt = ReceiptRecord(
        id: 'test-001',
        userId: 'user-123',
        imageUrl: 'https://example.com/receipt.jpg',
        amount: 12345.67,
        date: DateTime(2025, 10, 15),
        category: '식비',
        businessPurpose: '팀 회식',
        createdAt: DateTime(2025, 10, 15, 10, 30),
        isSubmitted: false,
      );
    });

    testWidgets('영수증 정보가 올바르게 표시', (tester) async {
      // Given: Receipt 객체
      // When: ReceiptCard 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptCard(receipt: testReceipt),
          ),
        ),
      );

      // Then: amount, date, category 표시 확인
      expect(find.text('₩12,346'), findsOneWidget); // 통화 형식
      expect(find.text('2025-10-15'), findsOneWidget); // 날짜 형식
      expect(find.text('식비'), findsOneWidget); // 카테고리
    });

    testWidgets('businessPurpose가 20자 초과 시 생략', (tester) async {
      // Given: businessPurpose가 30자인 Receipt
      final longReceipt = ReceiptRecord(
        id: 'test-002',
        userId: 'user-123',
        imageUrl: 'https://example.com/receipt.jpg',
        amount: 5000,
        date: DateTime(2025, 10, 15),
        category: '식비',
        businessPurpose: '이것은 매우 긴 업무 목적 설명입니다 30자 초과',
        createdAt: DateTime.now(),
        isSubmitted: false,
      );

      // When: ReceiptCard 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptCard(receipt: longReceipt),
          ),
        ),
      );

      // Then: "..." 생략 표시 확인
      expect(find.textContaining('...'), findsOneWidget);
    });

    testWidgets('amount가 통화 형식으로 표시', (tester) async {
      // Given: amount = 12345.67
      // When: ReceiptCard 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptCard(receipt: testReceipt),
          ),
        ),
      );

      // Then: "₩12,346" 형식 표시 (소수점 반올림)
      expect(find.text('₩12,346'), findsOneWidget);
      expect(find.text('12345.67'), findsNothing);
    });

    testWidgets('이미지 썸네일이 80x80으로 표시', (tester) async {
      // Given: imageUrl 포함 Receipt
      // When: ReceiptCard 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptCard(receipt: testReceipt),
          ),
        ),
      );

      // Then: Image.network 위젯 크기 80x80 확인
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final Image imageWidget = tester.widget(imageFinder);
      expect(imageWidget.width, 80);
      expect(imageWidget.height, 80);
    });

    testWidgets('category가 Chip으로 표시', (tester) async {
      // Given: category 포함 Receipt
      // When: ReceiptCard 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptCard(receipt: testReceipt),
          ),
        ),
      );

      // Then: Chip 위젯 내 카테고리 텍스트 확인
      expect(find.byType(Chip), findsOneWidget);
      expect(find.text('식비'), findsOneWidget);
    });

    testWidgets('imageUrl이 null일 때 플레이스홀더 표시', (tester) async {
      // Given: imageUrl이 빈 Receipt
      final noImageReceipt = ReceiptRecord(
        id: 'test-003',
        userId: 'user-123',
        imageUrl: '',
        amount: 5000,
        date: DateTime(2025, 10, 15),
        category: '교통',
        createdAt: DateTime.now(),
        isSubmitted: false,
      );

      // When: ReceiptCard 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptCard(receipt: noImageReceipt),
          ),
        ),
      );

      // Then: Container(grey) 플레이스홀더 표시
      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == 80 &&
            widget.constraints?.maxHeight == 80,
      );
      expect(containerFinder, findsOneWidget);
    });
  });
}
