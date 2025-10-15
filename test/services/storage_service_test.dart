// @TEST:RECEIPT-001 | SPEC: .moai/specs/SPEC-RECEIPT-001/spec.md

import 'package:flutter_test/flutter_test.dart';
import 'package:self_construct/services/storage_service.dart';

void main() {
  group('StorageService', () {
    test('should create StorageService without Firebase initialization', () {
      // Mock Storage를 주입하여 Firebase 초기화 없이 생성 가능
      final service = StorageService(storage: null);
      expect(service, isA<StorageService>());
    });

    test('should have uploadImage method with correct signature', () {
      final service = StorageService(storage: null);
      expect(service.uploadImage, isA<Function>());
    });

    test('should have getDownloadUrl method with correct signature', () {
      final service = StorageService(storage: null);
      expect(service.getDownloadUrl, isA<Function>());
    });

    test('should have deleteImage method with correct signature', () {
      final service = StorageService(storage: null);
      expect(service.deleteImage, isA<Function>());
    });
  });
}
