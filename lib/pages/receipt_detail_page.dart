// @CODE:RECEIPT-003:UI | SPEC: .moai/specs/SPEC-RECEIPT-003/spec.md | TEST: test/pages/receipt_detail_page_test.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/receipt_record.dart';

/// 영수증 상세 화면
///
/// SPEC 요구사항:
/// - 전체 크기 이미지 표시
/// - 모든 정보 표시 (금액, 날짜, 카테고리, 업무 목적, 제출 상태)
/// - 조건부 버튼 렌더링:
///   - isSubmitted: false → 수정/삭제/제출 버튼
///   - isSubmitted: true → 안내 메시지
/// - 수정 기능: /receipt/{id}/edit 이동
/// - 삭제 기능: Storage + Firestore 삭제
/// - 제출 기능: isSubmitted: true 업데이트
class ReceiptDetailPage extends StatefulWidget {
  final String receiptId;

  const ReceiptDetailPage({
    super.key,
    required this.receiptId,
  });

  @override
  State<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  ReceiptRecord? _receipt;
  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  /// Firestore에서 영수증 로드
  Future<void> _loadReceipt() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('receipts')
          .doc(widget.receiptId)
          .get();

      if (!doc.exists) {
        setState(() {
          _errorMessage = '영수증을 찾을 수 없습니다';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _receipt = ReceiptRecord.fromSnapshot(doc);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '영수증 로딩 실패: $e';
        _isLoading = false;
      });
    }
  }

  /// 수정 화면으로 이동
  void _navigateToEdit() {
    context.push('/receipt/${widget.receiptId}/edit');
  }

  /// 삭제 확인 다이얼로그
  Future<void> _showDeleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('영수증 삭제'),
        content: const Text(
          '정말로 이 영수증을 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteReceipt();
    }
  }

  /// Firestore + Storage 삭제
  Future<void> _deleteReceipt() async {
    setState(() => _isDeleting = true);

    try {
      // 1. Storage 이미지 삭제
      final imageUrl = _receipt!.imageUrl;
      if (imageUrl.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          // Storage 삭제 실패는 무시 (파일이 이미 없을 수 있음)
          debugPrint('Storage 삭제 실패 (무시): $e');
        }
      }

      // 2. Firestore 문서 삭제
      await FirebaseFirestore.instance
          .collection('receipts')
          .doc(widget.receiptId)
          .delete();

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text('영수증이 삭제되었습니다'),
          ),
        );
        context.go('/'); // 목록 화면으로 복귀
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('삭제 실패: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  /// 제출 확인 다이얼로그
  Future<void> _showSubmitDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('영수증 제출'),
        content: const Text(
          '영수증을 제출하시겠습니까? 제출 후에는 수정 및 삭제가 불가능합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('제출'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _submitReceipt();
    }
  }

  /// Firestore isSubmitted: true 업데이트
  Future<void> _submitReceipt() async {
    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance
          .collection('receipts')
          .doc(widget.receiptId)
          .update({
        'isSubmitted': true,
      });

      setState(() {
        _receipt = _receipt!.copyWith(isSubmitted: true);
      });

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text('영수증이 제출되었습니다'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('제출 실패: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('영수증 상세'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null || _receipt == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('영수증 상세'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? '영수증을 찾을 수 없습니다',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('목록으로 돌아가기'),
              ),
            ],
          ),
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('yyyy-MM-dd');
    final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('영수증 상세'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 전체 크기 이미지
            CachedNetworkImage(
              imageUrl: _receipt!.imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => Container(
                height: 300,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 300,
                color: Colors.grey[200],
                child: const Icon(Icons.error, size: 64),
              ),
            ),
            const SizedBox(height: 16),

            // 정보 카드
            Padding(
              padding: const EdgeInsets.all(16),
              child: ShadCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 금액
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '금액',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          currencyFormat.format(_receipt!.amount),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // 날짜
                    _buildInfoRow(
                      '날짜',
                      dateFormat.format(_receipt!.date),
                    ),
                    const SizedBox(height: 12),

                    // 카테고리
                    if (_receipt!.category != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '카테고리',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          ShadBadge(
                            child: Text(_receipt!.category!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 업무 목적
                    if (_receipt!.businessPurpose != null) ...[
                      const Text(
                        '업무 목적',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _receipt!.businessPurpose!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 제출 상태
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '제출 상태',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        ShadBadge(
                          backgroundColor: _receipt!.isSubmitted
                              ? Colors.green[100]
                              : Colors.orange[100],
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _receipt!.isSubmitted
                                    ? Icons.check_circle
                                    : Icons.schedule,
                                size: 14,
                                color: _receipt!.isSubmitted
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _receipt!.isSubmitted ? '제출됨' : '대기중',
                                style: TextStyle(
                                  color: _receipt!.isSubmitted
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 생성일
                    _buildInfoRow(
                      '생성일',
                      dateTimeFormat.format(_receipt!.createdAt),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 조건부 하단 버튼
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    if (_receipt!.isSubmitted) {
      // 제출 후: 안내 메시지
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[200],
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '이미 제출된 영수증입니다. 수정 및 삭제가 불가능합니다.',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      );
    }

    // 제출 전: 수정/삭제/제출 버튼
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 수정 버튼
          Expanded(
            child: ShadButton(
              onPressed: _isDeleting || _isSubmitting ? null : _navigateToEdit,
              child: const Text('수정'),
            ),
          ),
          const SizedBox(width: 8),

          // 삭제 버튼
          Expanded(
            child: ShadButton.destructive(
              onPressed: _isDeleting || _isSubmitting ? null : _showDeleteDialog,
              child: _isDeleting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('삭제'),
            ),
          ),
          const SizedBox(width: 8),

          // 제출 버튼
          Expanded(
            child: ShadButton(
              onPressed: _isDeleting || _isSubmitting ? null : _showSubmitDialog,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('제출'),
            ),
          ),
        ],
      ),
    );
  }
}
