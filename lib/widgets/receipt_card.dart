// @CODE:RECEIPT-002:UI | SPEC: .moai/specs/SPEC-RECEIPT-002/spec.md | TEST: test/widgets/receipt_card_test.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/receipt_record.dart';

/// 영수증 카드 위젯
/// FlutterFlow 스타일: 간단하고 직관적인 카드 UI
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        // 이미지 썸네일 80x80
        leading: receipt.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: receipt.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              )
            : Container(
                width: 80,
                height: 80,
                color: Colors.grey[300],
                constraints: const BoxConstraints(
                  maxWidth: 80,
                  maxHeight: 80,
                ),
              ),
        // 영수증 정보
        title: Text(
          displayBusinessPurpose.isNotEmpty
              ? displayBusinessPurpose
              : '업무 목적 미입력',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // 금액 (통화 형식)
            Text(
              currencyFormat.format(receipt.amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            // 날짜
            Text(
              dateFormat.format(receipt.date),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            // 카테고리 Chip
            if (receipt.category != null)
              Chip(
                label: Text(
                  receipt.category!,
                  style: const TextStyle(fontSize: 12),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}
