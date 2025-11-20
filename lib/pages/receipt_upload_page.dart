// @CODE:RECEIPT-001 | SPEC: .moai/specs/SPEC-RECEIPT-001/spec.md | TEST: test/pages/receipt_upload_page_test.dart

import 'package:flutter/material.dart';

/// 영수증 업로드 페이지
/// FlutterFlow 스타일: 간단하고 직관적인 UI
class ReceiptUploadPage extends StatefulWidget {
  const ReceiptUploadPage({super.key});

  @override
  State<ReceiptUploadPage> createState() => _ReceiptUploadPageState();
}

class _ReceiptUploadPageState extends State<ReceiptUploadPage> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _businessPurposeController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _businessPurposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영수증 업로드'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이미지 업로드 버튼
            ElevatedButton.icon(
              onPressed: () {
                // TODO: 이미지 선택 로직
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('이미지 선택'),
            ),
            const SizedBox(height: 16),

            // 금액 입력
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: '금액',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // 카테고리 입력
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: '카테고리 (선택)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 비즈니스 용도 입력
            TextField(
              controller: _businessPurposeController,
              decoration: const InputDecoration(
                labelText: '비즈니스 용도 (선택)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // 제출 버튼
            ElevatedButton(
              onPressed: () {
                // TODO: 제출 로직
              },
              child: const Text('제출'),
            ),
          ],
        ),
      ),
    );
  }
}
