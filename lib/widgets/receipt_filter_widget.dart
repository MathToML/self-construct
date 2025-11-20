// @CODE:RECEIPT-004 | SPEC: .moai/specs/SPEC-RECEIPT-004/spec.md
// TDD: REFACTOR - 재사용 가능한 필터 UI 위젯

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 영수증 필터 위젯
/// 검색, 카테고리, 날짜, 금액, 상태 필터 UI 제공
class ReceiptFilterWidget extends StatelessWidget {
  final String keyword;
  final String? selectedCategory;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final bool? isSubmitted;
  final ValueChanged<String> onKeywordChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onStartDatePressed;
  final VoidCallback onEndDatePressed;
  final ValueChanged<String> onMinAmountChanged;
  final ValueChanged<String> onMaxAmountChanged;
  final ValueChanged<bool?> onStatusChanged;

  const ReceiptFilterWidget({
    super.key,
    required this.keyword,
    required this.selectedCategory,
    required this.startDate,
    required this.endDate,
    required this.minAmount,
    required this.maxAmount,
    required this.isSubmitted,
    required this.onKeywordChanged,
    required this.onCategoryChanged,
    required this.onStartDatePressed,
    required this.onEndDatePressed,
    required this.onMinAmountChanged,
    required this.onMaxAmountChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final categories = ['식비', '교통', '숙박', '기타'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 키워드 검색
          TextField(
            decoration: const InputDecoration(
              labelText: '업무 목적 검색',
              hintText: '출장, 미팅, 회의 등...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: onKeywordChanged,
          ),
          const SizedBox(height: 12),

          // 카테고리 + 상태 필터
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: '카테고리',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('전체'),
                    ),
                    ...categories.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        )),
                  ],
                  onChanged: onCategoryChanged,
                ),
              ),
              const SizedBox(width: 12),

              // 제출 상태 토글
              Expanded(
                child: SegmentedButton<bool?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('전체')),
                    ButtonSegment(value: true, label: Text('제출됨')),
                    ButtonSegment(value: false, label: Text('대기중')),
                  ],
                  selected: {isSubmitted},
                  onSelectionChanged: (Set<bool?> selected) {
                    onStatusChanged(selected.first);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 날짜 범위
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    startDate == null ? '시작일' : dateFormat.format(startDate!),
                  ),
                  onPressed: onStartDatePressed,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('~'),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    endDate == null ? '종료일' : dateFormat.format(endDate!),
                  ),
                  onPressed: onEndDatePressed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 금액 범위
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '최소 금액',
                    border: OutlineInputBorder(),
                    suffixText: '원',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: onMinAmountChanged,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('~'),
              ),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '최대 금액',
                    border: OutlineInputBorder(),
                    suffixText: '원',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: onMaxAmountChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 활성 필터 배지 위젯
class ActiveFiltersBadge extends StatelessWidget {
  final int activeCount;

  const ActiveFiltersBadge({
    super.key,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue[50],
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            '$activeCount개의 필터 적용 중',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
