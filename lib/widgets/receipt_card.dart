// @CODE:RECEIPT-002:UI | SPEC: .moai/specs/SPEC-RECEIPT-002/spec.md | TEST: test/widgets/receipt_card_test.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/receipt_record.dart';

/// 영수증 카드 위젯
///
/// shadcn_ui 스타일: ShadCard 기반 간단하고 직관적한 카드 UI
///
/// SPEC 요구사항:
/// - businessPurpose 20자 초과 시 "..." 생략
/// - amount 통화 형식 (₩12,346)
/// - date yyyy-MM-dd 형식
/// - 이미지 썸네일 80x80 (CachedNetworkImage)
/// - 카테고리 ShadBadge 표시
///
/// @CODE:RECEIPT-003 - 클릭 이벤트 추가
/// - onTap: 상세 페이지(/receipt/{id})로 이동
class ReceiptCard extends StatelessWidget {
  final ReceiptRecord receipt;

  const ReceiptCard({
    super.key,
    required this.receipt,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('yyyy-MM-dd');

    // businessPurpose 20자 초과 시 생략
    String displayBusinessPurpose = receipt.businessPurpose ?? '';
    if (displayBusinessPurpose.length > 20) {
      displayBusinessPurpose = '${displayBusinessPurpose.substring(0, 20)}...';
    }

    return GestureDetector(
      onTap: () {
        // @CODE:RECEIPT-003 - 상세 페이지로 이동
        context.push('/receipt/${receipt.id}');
      },
      child: ShadCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // 이미지 썸네일 80x80
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: receipt.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: receipt.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.error),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                  ),
          ),
          const SizedBox(width: 16),
          // 영수증 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // businessPurpose (제목)
                Text(
                  displayBusinessPurpose.isNotEmpty
                      ? displayBusinessPurpose
                      : '업무 목적 미입력',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // 금액 (통화 형식)
                Text(
                  currencyFormat.format(receipt.amount),
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // 날짜
                Text(
                  dateFormat.format(receipt.date),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                // 카테고리 Badge 및 제출 상태
                Row(
                  children: [
                    if (receipt.category != null)
                      ShadBadge(
                        child: Text(receipt.category!),
                      ),
                    if (receipt.category != null) const SizedBox(width: 8),
                    // 제출 상태 표시
                    ShadBadge(
                      backgroundColor: receipt.isSubmitted
                          ? Colors.green[100]
                          : Colors.orange[100],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            receipt.isSubmitted
                                ? Icons.check_circle
                                : Icons.schedule,
                            size: 14,
                            color: receipt.isSubmitted
                                ? Colors.green[700]
                                : Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            receipt.isSubmitted ? '제출됨' : '대기중',
                            style: TextStyle(
                              color: receipt.isSubmitted
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
