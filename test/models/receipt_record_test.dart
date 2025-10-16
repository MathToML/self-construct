// @TEST:RECEIPT-001 | SPEC: .moai/specs/SPEC-RECEIPT-001/spec.md

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:self_construct/models/receipt_record.dart';

void main() {
  group('ReceiptRecord', () {
    test('fromSnapshot should convert DocumentSnapshot to ReceiptRecord', () {
      // Arrange
      final data = {
        'userId': 'user123',
        'imageUrl': 'https://example.com/image.jpg',
        'amount': 100.50,
        'date': Timestamp.fromDate(DateTime(2025, 10, 14)),
        'category': 'Food',
        'businessPurpose': 'Client meeting',
        'createdAt': Timestamp.fromDate(DateTime(2025, 10, 14)),
        'isSubmitted': true,
      };

      final mockSnapshot = MockDocumentSnapshot('receipt123', data);

      // Act
      final receipt = ReceiptRecord.fromSnapshot(mockSnapshot);

      // Assert
      expect(receipt.id, 'receipt123');
      expect(receipt.userId, 'user123');
      expect(receipt.amount, 100.50);
      expect(receipt.isSubmitted, true);
    });

    test('toMap should convert ReceiptRecord to Map', () {
      // Arrange
      final receipt = ReceiptRecord(
        id: 'receipt123',
        userId: 'user123',
        imageUrl: 'https://example.com/image.jpg',
        amount: 100.50,
        date: DateTime(2025, 10, 14),
        category: 'Food',
        businessPurpose: 'Client meeting',
        createdAt: DateTime(2025, 10, 14),
        isSubmitted: true,
      );

      // Act
      final map = receipt.toMap();

      // Assert
      expect(map['userId'], 'user123');
      expect(map['amount'], 100.50);
      expect(map['isSubmitted'], true);
    });

    // @TEST:RECEIPT-003 - copyWith 메서드 테스트
    test('copyWith should create a new instance with updated fields', () {
      // Arrange
      final original = ReceiptRecord(
        id: 'receipt123',
        userId: 'user123',
        imageUrl: 'https://example.com/image.jpg',
        amount: 100.50,
        date: DateTime(2025, 10, 14),
        category: 'Food',
        businessPurpose: 'Client meeting',
        createdAt: DateTime(2025, 10, 14),
        isSubmitted: false,
      );

      // Act
      final updated = original.copyWith(isSubmitted: true);

      // Assert
      expect(updated.id, original.id);
      expect(updated.userId, original.userId);
      expect(updated.isSubmitted, true); // 변경된 필드
      expect(original.isSubmitted, false); // 원본은 불변
    });

    test('copyWith should update multiple fields', () {
      // Arrange
      final original = ReceiptRecord(
        id: 'receipt123',
        userId: 'user123',
        imageUrl: 'https://example.com/image.jpg',
        amount: 100.50,
        date: DateTime(2025, 10, 14),
        category: 'Food',
        businessPurpose: 'Client meeting',
        createdAt: DateTime(2025, 10, 14),
        isSubmitted: false,
      );

      // Act
      final updated = original.copyWith(
        amount: 200.0,
        category: 'Transport',
      );

      // Assert
      expect(updated.amount, 200.0);
      expect(updated.category, 'Transport');
      expect(updated.id, original.id); // 변경되지 않은 필드
    });
  });
}

// Mock DocumentSnapshot (테스트용)
class MockDocumentSnapshot implements DocumentSnapshot {
  final String _id;
  final Map<String, dynamic> _data;

  MockDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
