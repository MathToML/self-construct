// @CODE:RECEIPT-002:UI | SPEC: .moai/specs/SPEC-RECEIPT-002/spec.md | TEST: test/pages/receipt_list_page_test.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../models/receipt_record.dart';
import '../widgets/receipt_card.dart';

/// 영수증 목록 페이지
///
/// FlutterFlow 스타일: StreamBuilder 기반 실시간 목록 조회
///
/// SPEC 요구사항:
/// - StreamBuilder로 Firestore 실시간 조회
/// - userId 필터링, date 내림차순 정렬
/// - 로딩/에러/빈 목록 상태 처리
/// - ReceiptCard로 목록 표시
/// - FloatingActionButton으로 업로드 화면 이동
class ReceiptListPage extends StatelessWidget {
  const ReceiptListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(auth: FirebaseAuth.instance);
    final userId = authService.getCurrentUser();

    // 사용자가 없으면 로그인 페이지로 리다이렉트
    if (userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('receipts')
            .where('userId', isEqualTo: userId)
            .orderBy('date', descending: true) // 최신순 정렬
            .snapshots(),
        builder: (context, snapshot) {
          // 로딩 상태
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 에러 상태
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('에러: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // 새로고침
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          // 빈 목록
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '등록된 영수증이 없습니다',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '아래 + 버튼을 눌러 영수증을 추가하세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // 영수증 목록 표시
          final receipts = snapshot.data!.docs
              .map((doc) => ReceiptRecord.fromSnapshot(doc))
              .toList();

          return ListView.builder(
            itemCount: receipts.length,
            itemBuilder: (context, index) {
              return ReceiptCard(receipt: receipts[index]);
            },
          );
        },
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
