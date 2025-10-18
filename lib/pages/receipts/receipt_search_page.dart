// @CODE:RECEIPT-004 | SPEC: .moai/specs/SPEC-RECEIPT-004/spec.md
// TDD: REFACTOR - 영수증 검색 및 필터링 UI (리팩토링)
//
// TDD History:
// - RED: test/utils/receipt_filter_test.dart, test/utils/debounce_test.dart
// - GREEN: Minimal implementation with all filter logic
// - REFACTOR: Extract filter UI to separate widget, reduce LOC < 300

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../models/receipt_record.dart';
import '../../services/firestore_service.dart';
import '../../utils/debounce.dart';
import '../../utils/receipt_filter.dart';
import '../../widgets/receipt_filter_widget.dart';

/// 영수증 검색 및 필터링 페이지
class ReceiptSearchPage extends StatefulWidget {
  const ReceiptSearchPage({super.key});

  @override
  State<ReceiptSearchPage> createState() => _ReceiptSearchPageState();
}

class _ReceiptSearchPageState extends State<ReceiptSearchPage> {
  final _firestoreService = FirestoreService();
  final _debouncer = Debouncer(milliseconds: 300);
  final _dateFormat = DateFormat('yyyy-MM-dd');

  // Filter state
  String _keyword = '';
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  bool? _isSubmitted;

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  /// 필터 초기화
  void _resetFilters() {
    setState(() {
      _keyword = '';
      _selectedCategory = null;
      _startDate = null;
      _endDate = null;
      _minAmount = null;
      _maxAmount = null;
      _isSubmitted = null;
    });
  }

  /// 현재 필터 생성
  ReceiptFilter _buildFilter() {
    return ReceiptFilter(
      keyword: _keyword.isEmpty ? null : _keyword,
      category: _selectedCategory,
      startDate: _startDate,
      endDate: _endDate,
      minAmount: _minAmount,
      maxAmount: _maxAmount,
      isSubmitted: _isSubmitted,
    );
  }

  /// 날짜 선택기
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('영수증 검색'),
        actions: [
          if (_buildFilter().hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: '필터 초기화',
              onPressed: _resetFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          // 필터 UI (분리된 위젯 사용)
          ReceiptFilterWidget(
            keyword: _keyword,
            selectedCategory: _selectedCategory,
            startDate: _startDate,
            endDate: _endDate,
            minAmount: _minAmount,
            maxAmount: _maxAmount,
            isSubmitted: _isSubmitted,
            onKeywordChanged: (value) {
              _debouncer.run(() {
                setState(() {
                  _keyword = value;
                });
              });
            },
            onCategoryChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            onStartDatePressed: () => _selectDate(context, true),
            onEndDatePressed: () => _selectDate(context, false),
            onMinAmountChanged: (value) {
              setState(() {
                _minAmount = double.tryParse(value);
              });
            },
            onMaxAmountChanged: (value) {
              setState(() {
                _maxAmount = double.tryParse(value);
              });
            },
            onStatusChanged: (value) {
              setState(() {
                _isSubmitted = value;
              });
            },
          ),

          // 활성 필터 배지
          if (_buildFilter().hasActiveFilters)
            ActiveFiltersBadge(
              activeCount: _buildFilter().activeFilterCount,
            ),

          // 검색 결과
          Expanded(child: _buildSearchResults(user.uid)),
        ],
      ),
    );
  }

  /// 검색 결과 목록
  Widget _buildSearchResults(String userId) {
    return StreamBuilder<List<ReceiptRecord>>(
      stream: _firestoreService.getReceiptsForSearch(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('오류: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('영수증이 없습니다'));
        }

        // 클라이언트 사이드 필터링
        final allReceipts = snapshot.data!;
        final filter = _buildFilter();
        final filteredReceipts = filter.apply(allReceipts);

        if (filteredReceipts.isEmpty) {
          return const Center(child: Text('검색 결과가 없습니다'));
        }

        return ListView.builder(
          itemCount: filteredReceipts.length,
          itemBuilder: (context, index) {
            final receipt = filteredReceipts[index];
            return _buildReceiptCard(receipt);
          },
        );
      },
    );
  }

  /// 영수증 카드 UI
  Widget _buildReceiptCard(ReceiptRecord receipt) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.receipt, size: 40),
        title: Text(
          receipt.businessPurpose ?? '(목적 없음)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('금액: ${NumberFormat('#,###원').format(receipt.amount)}'),
            Text('카테고리: ${receipt.category ?? '미분류'}'),
            Text('날짜: ${_dateFormat.format(receipt.date)}'),
          ],
        ),
        trailing: Icon(
          receipt.isSubmitted ? Icons.check_circle : Icons.pending,
          color: receipt.isSubmitted ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}
