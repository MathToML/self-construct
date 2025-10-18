// @TEST:RECEIPT-004 | SPEC: .moai/specs/SPEC-RECEIPT-004/spec.md

import 'package:flutter_test/flutter_test.dart';
import 'package:self_construct/models/receipt_record.dart';
import 'package:self_construct/utils/receipt_filter.dart';

void main() {
  group('ReceiptFilter', () {
    late List<ReceiptRecord> sampleReceipts;

    setUp(() {
      sampleReceipts = [
        ReceiptRecord(
          id: 'r1',
          userId: 'user1',
          imageUrl: 'https://example.com/1.jpg',
          amount: 50000,
          date: DateTime(2025, 10, 15),
          category: '식비',
          businessPurpose: '고객 미팅 점심',
          createdAt: DateTime(2025, 10, 15),
          isSubmitted: true,
        ),
        ReceiptRecord(
          id: 'r2',
          userId: 'user1',
          imageUrl: 'https://example.com/2.jpg',
          amount: 120000,
          date: DateTime(2025, 10, 16),
          category: '교통',
          businessPurpose: '서울 출장 택시비',
          createdAt: DateTime(2025, 10, 16),
          isSubmitted: false,
        ),
        ReceiptRecord(
          id: 'r3',
          userId: 'user1',
          imageUrl: 'https://example.com/3.jpg',
          amount: 200000,
          date: DateTime(2025, 10, 17),
          category: '숙박',
          businessPurpose: '부산 출장 호텔비',
          createdAt: DateTime(2025, 10, 17),
          isSubmitted: true,
        ),
      ];
    });

    // RED: Keyword search tests
    test('should filter by keyword (case-insensitive)', () {
      // Given
      final filter = ReceiptFilter(keyword: '출장');

      // When
      final result = filter.apply(sampleReceipts);

      // Then
      expect(result.length, 2); // r2, r3
      expect(result.map((r) => r.id), containsAll(['r2', 'r3']));
    });

    test('should return all receipts when keyword is empty', () {
      // Given
      final filter = ReceiptFilter(keyword: '');

      // When
      final result = filter.apply(sampleReceipts);

      // Then
      expect(result.length, 3);
    });

    test('should return empty list when keyword matches nothing', () {
      // Given
      final filter = ReceiptFilter(keyword: '존재하지않는키워드');

      // When
      final result = filter.apply(sampleReceipts);

      // Then
      expect(result, isEmpty);
    });

    // RED: Category filter tests
    test('should filter by category', () {
      // Given
      final filter = ReceiptFilter(category: '교통');

      // When
      final result = filter.apply(sampleReceipts);

      // Then
      expect(result.length, 1);
      expect(result.first.id, 'r2');
    });

    test('should return all receipts when category is null', () {
      // Given
      final filter = ReceiptFilter(category: null);

      // When
      final result = filter.apply(sampleReceipts);

      // Then
      expect(result.length, 3);
    });

    // RED: Date range filter tests
    test('should filter by date range', () {
      // Given
      final filter = ReceiptFilter(
        startDate: DateTime(2025, 10, 16),
        endDate: DateTime(2025, 10, 17),
      );

      // When
      final result = filter.apply(sampleReceipts);

      // Then
      expect(result.length, 2); // r2, r3
      expect(result.map((r) => r.id), containsAll(['r2', 'r3']));
    });

    test('should filter by start date only', () {
      // Given
      final filter = ReceiptFilter(
        startDate: DateTime(2025, 10, 16),
      );

      // When
      final result = filter.apply(sampleReceipts);

      // Then
      expect(result.length, 2); // r2, r3
    });

    test('should filter by end date only', () {
      // Given
      final filter = ReceiptFilter(
        endDate: DateTime(2025, 10, 16),
      );

      // When
      final result = filter.apply(sampleReceipts);

      // Then
      expect(result.length, 2); // r1, r2
    });

    // RED: Amount range filter tests
    test('should filter by amount range', () {
      // Given
      final filter = ReceiptFilter(
        minAmount: 100000,
        maxAmount: 200000,
      );

      // When
      final result = filter.apply(sampleReceipts);

      // Then
      expect(result.length, 2); // r2, r3
      expect(result.map((r) => r.id), containsAll(['r2', 'r3']));
    });

    test('should filter by min amount only', () {
      // Given
      final filter = ReceiptFilter(
        minAmount: 120000,
      );

      // When
      final result = filter.apply(sampleReceipts);

      // Then
      expect(result.length, 2); // r2, r3
    });

    test('should filter by max amount only', () {
      // Given
      final filter = ReceiptFilter(
        maxAmount: 120000,
      );

      // When
      final result = filter.apply(sampleReceipts);

      // Then
      expect(result.length, 2); // r1, r2
    });

    // RED: Status filter tests
    test('should filter by isSubmitted status', () {
      // Given
      final filter = ReceiptFilter(isSubmitted: true);

      // When
      final result = filter.apply(sampleReceipts);

      // Then
      expect(result.length, 2); // r1, r3
      expect(result.every((r) => r.isSubmitted), isTrue);
    });

    test('should filter by not submitted status', () {
      // Given
      final filter = ReceiptFilter(isSubmitted: false);

      // When
      final result = filter.apply(sampleReceipts);

      // Then
      expect(result.length, 1); // r2
      expect(result.first.isSubmitted, isFalse);
    });

    // RED: Combined filters test
    test('should apply multiple filters together', () {
      // Given
      final filter = ReceiptFilter(
        keyword: '출장',
        category: '교통',
        isSubmitted: false,
      );

      // When
      final result = filter.apply(sampleReceipts);

      // Then
      expect(result.length, 1);
      expect(result.first.id, 'r2');
    });

    test('should validate date range (start <= end)', () {
      // Given/When/Then
      expect(
        () => ReceiptFilter(
          startDate: DateTime(2025, 10, 17),
          endDate: DateTime(2025, 10, 16),
        ),
        throwsArgumentError,
      );
    });

    test('should validate amount range (min <= max)', () {
      // Given/When/Then
      expect(
        () => ReceiptFilter(
          minAmount: 200000,
          maxAmount: 100000,
        ),
        throwsArgumentError,
      );
    });
  });
}
