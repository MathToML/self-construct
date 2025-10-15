// @CODE:RECEIPT-001 | SPEC: .moai/specs/SPEC-RECEIPT-001/spec.md | TEST: test/models/receipt_record_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// FlutterFlow 스타일 Record 클래스
/// Firestore DocumentSnapshot을 타입 안전하게 변환
class ReceiptRecord {
  final String id;
  final String userId;
  final String imageUrl;
  final double amount;
  final DateTime date;
  final String? category;
  final String? businessPurpose;
  final DateTime createdAt;
  final bool isSubmitted;

  ReceiptRecord({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.amount,
    required this.date,
    this.category,
    this.businessPurpose,
    required this.createdAt,
    required this.isSubmitted,
  });

  /// DocumentSnapshot → ReceiptRecord 변환
  factory ReceiptRecord.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ReceiptRecord(
      id: snapshot.id,
      userId: data['userId'] as String,
      imageUrl: data['imageUrl'] as String,
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] as String?,
      businessPurpose: data['businessPurpose'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isSubmitted: data['isSubmitted'] as bool? ?? false,
    );
  }

  /// ReceiptRecord → Map (Firestore 저장용)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'businessPurpose': businessPurpose,
      'createdAt': Timestamp.fromDate(createdAt),
      'isSubmitted': isSubmitted,
    };
  }
}
