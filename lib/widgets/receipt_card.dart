// @CODE:RECEIPT-002:UI | SPEC: .moai/specs/SPEC-RECEIPT-002/spec.md | TEST: test/widgets/receipt_card_test.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
class ReceiptCard extends StatelessWidget {
  final ReceiptRecord receipt;

  const ReceiptCard({
    super.key,
    required this.receipt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
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

    return ShadCard(
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
                      color: theme.colorScheme.muted,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: theme.colorScheme.muted,
                      child: const Icon(Icons.error),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: theme.colorScheme.muted,
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
                  style: theme.textTheme.large.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // 금액 (통화 형식)
                Text(
                  currencyFormat.format(receipt.amount),
                  style: theme.textTheme.h4.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // 날짜
                Text(
                  dateFormat.format(receipt.date),
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                // 카테고리 Badge
                if (receipt.category != null)
                  ShadBadge(
                    child: Text(receipt.category!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
