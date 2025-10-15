// @CODE:RECEIPT-001 | SPEC: .moai/specs/SPEC-RECEIPT-001/spec.md | TEST: test/services/auth_service_test.dart

import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Auth 서비스
/// FlutterFlow 스타일: 간단한 익명 로그인 지원
class AuthService {
  final FirebaseAuth? _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth;

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;

  /// 익명 로그인
  ///
  /// Returns: 로그인된 사용자 ID
  Future<String> signInAnonymously() async {
    try {
      final userCredential = await auth.signInAnonymously();
      return userCredential.user!.uid;
    } catch (e) {
      throw Exception('Anonymous sign-in failed: $e');
    }
  }

  /// 현재 로그인된 사용자 가져오기
  ///
  /// Returns: 사용자 ID (로그인하지 않았으면 null)
  String? getCurrentUser() {
    return auth.currentUser?.uid;
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// 인증 상태 변경 스트림
  ///
  /// Returns: 사용자 상태 변경 스트림
  Stream<User?> get authStateChanges => auth.authStateChanges();
}
