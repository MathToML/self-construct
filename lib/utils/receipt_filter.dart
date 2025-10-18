// @CODE:RECEIPT-004 | SPEC: .moai/specs/SPEC-RECEIPT-004/spec.md | TEST: test/utils/receipt_filter_test.dart
// TDD: GREEN - Client-side filtering logic

import 'package:self_construct/models/receipt_record.dart';

/// 영수증 필터 클래스
/// Firestore 쿼리 제약으로 인한 클라이언트 사이드 필터링
class ReceiptFilter {
  final String? keyword;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final bool? isSubmitted;

  ReceiptFilter({
    this.keyword,
    this.category,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.isSubmitted,
  }) {
    // 입력 검증
    if (startDate != null && endDate != null && startDate!.isAfter(endDate!)) {
      throw ArgumentError('Start date must be before or equal to end date');
    }
    if (minAmount != null && maxAmount != null && minAmount! > maxAmount!) {
      throw ArgumentError('Min amount must be less than or equal to max amount');
    }
  }

  /// 필터 적용
  List<ReceiptRecord> apply(List<ReceiptRecord> receipts) {
    var result = receipts;

    // Keyword filter (businessPurpose)
    if (keyword != null && keyword!.isNotEmpty) {
      result = result.where((r) {
        final purpose = r.businessPurpose?.toLowerCase() ?? '';
        return purpose.contains(keyword!.toLowerCase());
      }).toList();
    }

    // Category filter
    if (category != null) {
      result = result.where((r) => r.category == category).toList();
    }

    // Date range filter
    if (startDate != null) {
      result = result.where((r) {
        return r.date.isAtSameMomentAs(startDate!) || r.date.isAfter(startDate!);
      }).toList();
    }

    if (endDate != null) {
      result = result.where((r) {
        return r.date.isAtSameMomentAs(endDate!) || r.date.isBefore(endDate!);
      }).toList();
    }

    // Amount range filter
    if (minAmount != null) {
      result = result.where((r) => r.amount >= minAmount!).toList();
    }

    if (maxAmount != null) {
      result = result.where((r) => r.amount <= maxAmount!).toList();
    }

    // Status filter
    if (isSubmitted != null) {
      result = result.where((r) => r.isSubmitted == isSubmitted).toList();
    }

    return result;
  }

  /// 활성 필터 개수 확인
  int get activeFilterCount {
    var count = 0;
    if (keyword != null && keyword!.isNotEmpty) count++;
    if (category != null) count++;
    if (startDate != null || endDate != null) count++;
    if (minAmount != null || maxAmount != null) count++;
    if (isSubmitted != null) count++;
    return count;
  }

  /// 필터 초기화 여부
  bool get hasActiveFilters => activeFilterCount > 0;
}
