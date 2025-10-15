// @CODE:RECEIPT-001 | SPEC: .moai/specs/SPEC-RECEIPT-001/spec.md | TEST: test/pages/receipt_list_page_test.dart

import 'package:flutter/material.dart';

/// 영수증 목록 페이지
/// FlutterFlow 스타일: 간단하고 직관적인 리스트 UI
class ReceiptListPage extends StatelessWidget {
  const ReceiptListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영수증 목록'),
      ),
      body: const Center(
        child: Text('영수증 목록이 여기에 표시됩니다'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 영수증 업로드 페이지로 이동
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
