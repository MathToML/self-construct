// @CODE:RECEIPT-004 | SPEC: .moai/specs/SPEC-RECEIPT-004/spec.md | TEST: test/utils/debounce_test.dart
// TDD: GREEN - Minimal Debouncer implementation

import 'dart:async';

/// Debouncer 유틸리티
/// 300ms 지연으로 검색 입력을 디바운싱
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  /// 디바운싱된 콜백 실행
  /// 이전 타이머가 있으면 취소하고 새 타이머 시작
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// 대기 중인 타이머 취소
  void dispose() {
    _timer?.cancel();
  }
}
