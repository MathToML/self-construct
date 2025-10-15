// @TEST:RECEIPT-001 | SPEC: .moai/specs/SPEC-RECEIPT-001/spec.md

import 'package:flutter_test/flutter_test.dart';
import 'package:self_construct/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('should create AuthService without Firebase initialization', () {
      final service = AuthService(auth: null);
      expect(service, isA<AuthService>());
    });

    test('should have signInAnonymously method', () {
      final service = AuthService(auth: null);
      expect(service.signInAnonymously, isA<Function>());
    });

    test('should have getCurrentUser method', () {
      final service = AuthService(auth: null);
      expect(service.getCurrentUser, isA<Function>());
    });

    test('should have signOut method', () {
      final service = AuthService(auth: null);
      expect(service.signOut, isA<Function>());
    });
  });
}
