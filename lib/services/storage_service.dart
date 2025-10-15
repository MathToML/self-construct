// @CODE:RECEIPT-001 | SPEC: .moai/specs/SPEC-RECEIPT-001/spec.md | TEST: test/services/storage_service_test.dart

import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Storage 이미지 업로드/다운로드 서비스
/// FlutterFlow 스타일: 간단하고 직관적인 API
class StorageService {
  final FirebaseStorage? _storage;

  StorageService({FirebaseStorage? storage}) : _storage = storage;

  FirebaseStorage get storage => _storage ?? FirebaseStorage.instance;

  /// 이미지를 Firebase Storage에 업로드하고 다운로드 URL 반환
  ///
  /// [bytes]: 업로드할 이미지 바이트 데이터
  /// [fileName]: 파일명 (예: 'receipt_123.jpg')
  /// [userId]: 사용자 ID (경로 구성용)
  ///
  /// Returns: 업로드된 파일의 다운로드 URL
  Future<String> uploadImage(
    List<int> bytes,
    String fileName,
    String userId,
  ) async {
    try {
      // 저장 경로: receipts/{userId}/{fileName}
      final ref = storage.ref().child('receipts/$userId/$fileName');

      // 이미지 업로드 (메타데이터: JPEG)
      final uploadTask = await ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // 다운로드 URL 반환
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  /// 파일 경로로부터 다운로드 URL 가져오기
  ///
  /// [filePath]: Storage 경로 (예: 'receipts/user123/receipt.jpg')
  ///
  /// Returns: 다운로드 URL
  Future<String> getDownloadUrl(String filePath) async {
    try {
      final ref = storage.ref().child(filePath);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }

  /// Storage에서 이미지 삭제
  ///
  /// [filePath]: 삭제할 파일 경로
  Future<void> deleteImage(String filePath) async {
    try {
      final ref = storage.ref().child(filePath);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }
}
