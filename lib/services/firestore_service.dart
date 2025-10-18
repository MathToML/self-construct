// @CODE:RECEIPT-001 | SPEC: .moai/specs/SPEC-RECEIPT-001/spec.md | TEST: test/services/firestore_service_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:self_construct/models/receipt_record.dart';

/// Firestore CRUD 서비스
/// FlutterFlow 스타일: 컬렉션 기반 단순 CRUD
class FirestoreService {
  final FirebaseFirestore? _firestore;

  FirestoreService({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  /// 'receipts' 컬렉션 참조
  CollectionReference get receiptsCollection =>
      firestore.collection('receipts');

  /// 새 영수증 레코드 생성
  ///
  /// [receipt]: 생성할 영수증 데이터
  ///
  /// Returns: 생성된 문서 ID
  Future<String> createReceipt(ReceiptRecord receipt) async {
    try {
      final docRef = await receiptsCollection.add(receipt.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create receipt: $e');
    }
  }

  /// 특정 사용자의 영수증 목록 조회 (Stream)
  ///
  /// [userId]: 사용자 ID
  ///
  /// Returns: 영수증 레코드 스트림
  Stream<List<ReceiptRecord>> getReceipts(String userId) {
    try {
      return receiptsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => ReceiptRecord.fromSnapshot(doc)).toList());
    } catch (e) {
      throw Exception('Failed to get receipts: $e');
    }
  }

  /// 영수증 레코드 업데이트
  ///
  /// [receiptId]: 업데이트할 문서 ID
  /// [data]: 업데이트할 필드 맵
  Future<void> updateReceipt(String receiptId, Map<String, dynamic> data) async {
    try {
      await receiptsCollection.doc(receiptId).update(data);
    } catch (e) {
      throw Exception('Failed to update receipt: $e');
    }
  }

  /// 영수증 레코드 삭제
  ///
  /// [receiptId]: 삭제할 문서 ID
  Future<void> deleteReceipt(String receiptId) async {
    try {
      await receiptsCollection.doc(receiptId).delete();
    } catch (e) {
      throw Exception('Failed to delete receipt: $e');
    }
  }

  /// @CODE:RECEIPT-004 - 검색 및 필터링용 쿼리
  /// TDD: GREEN - Firestore 쿼리 빌더 (제한적 필터 지원)
  ///
  /// [userId]: 사용자 ID (필수)
  /// [limit]: 결과 제한 (기본값: 100)
  ///
  /// Note: Firestore 제약으로 인해 복잡한 필터는 클라이언트 사이드에서 처리
  Stream<List<ReceiptRecord>> getReceiptsForSearch(
    String userId, {
    int limit = 100,
  }) {
    try {
      return receiptsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ReceiptRecord.fromSnapshot(doc))
              .toList());
    } catch (e) {
      throw Exception('Failed to get receipts for search: $e');
    }
  }
}
