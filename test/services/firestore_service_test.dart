// @TEST:RECEIPT-001 | SPEC: .moai/specs/SPEC-RECEIPT-001/spec.md

import 'package:flutter_test/flutter_test.dart';
import 'package:self_construct/services/firestore_service.dart';

void main() {
  group('FirestoreService', () {
    test('should create FirestoreService without Firebase initialization', () {
      final service = FirestoreService(firestore: null);
      expect(service, isA<FirestoreService>());
    });

    test('should have createReceipt method', () {
      final service = FirestoreService(firestore: null);
      expect(service.createReceipt, isA<Function>());
    });

    test('should have getReceipts method', () {
      final service = FirestoreService(firestore: null);
      expect(service.getReceipts, isA<Function>());
    });

    test('should have updateReceipt method', () {
      final service = FirestoreService(firestore: null);
      expect(service.updateReceipt, isA<Function>());
    });

    test('should have deleteReceipt method', () {
      final service = FirestoreService(firestore: null);
      expect(service.deleteReceipt, isA<Function>());
    });
  });
}
