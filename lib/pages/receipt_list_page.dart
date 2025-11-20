// @CODE:RECEIPT-001 | SPEC: .moai/specs/SPEC-RECEIPT-001/spec.md | TEST: test/pages/receipt_list_page_test.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

/// 영수증 목록 페이지
/// FlutterFlow 스타일: 간단하고 직관적인 리스트 UI
class ReceiptListPage extends StatelessWidget {
  const ReceiptListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(auth: FirebaseAuth.instance);

    return Scaffold(
      appBar: AppBar(
        title: const Text('영수증 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: const Center(
        child: Text('영수증 목록이 여기에 표시됩니다'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/upload');
        },
        tooltip: '영수증 추가',
        child: const Icon(Icons.add),
      ),
    );
  }
}
