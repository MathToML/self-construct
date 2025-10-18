// @TEST:RECEIPT-004 | SPEC: .moai/specs/SPEC-RECEIPT-004/spec.md

import 'package:flutter_test/flutter_test.dart';
import 'package:self_construct/utils/debounce.dart';

void main() {
  group('Debouncer', () {
    test('should execute callback after delay', () async {
      // Given
      var callCount = 0;
      final debouncer = Debouncer(milliseconds: 100);

      // When
      debouncer.run(() {
        callCount++;
      });

      // Then - Immediate check
      expect(callCount, 0);

      // Wait for debounce delay
      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 1);
    });

    test('should cancel previous timer on new call', () async {
      // Given
      var callCount = 0;
      final debouncer = Debouncer(milliseconds: 100);

      // When - Multiple rapid calls
      debouncer.run(() {
        callCount++;
      });

      await Future.delayed(const Duration(milliseconds: 50));

      debouncer.run(() {
        callCount++;
      });

      // Then - Only the last call should execute
      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 1);
    });

    test('should cancel pending timer on dispose', () async {
      // Given
      var callCount = 0;
      final debouncer = Debouncer(milliseconds: 100);

      // When
      debouncer.run(() {
        callCount++;
      });

      debouncer.dispose();

      // Then - Callback should not execute
      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 0);
    });

    test('should handle multiple calls with correct timing', () async {
      // Given
      var callCount = 0;
      final debouncer = Debouncer(milliseconds: 100);

      // When - First call
      debouncer.run(() {
        callCount++;
      });

      await Future.delayed(const Duration(milliseconds: 150));

      // Second call after first completed
      debouncer.run(() {
        callCount++;
      });

      await Future.delayed(const Duration(milliseconds: 150));

      // Then - Both calls should execute
      expect(callCount, 2);
    });
  });
}
