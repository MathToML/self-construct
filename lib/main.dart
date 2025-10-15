// @CODE:RECEIPT-001 | SPEC: .moai/specs/SPEC-RECEIPT-001/spec.md
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'firebase_options.dart';
import 'pages/receipt_list_page.dart';
import 'pages/receipt_upload_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ReceiptFlowApp());
}

class ReceiptFlowApp extends StatelessWidget {
  const ReceiptFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      home: MaterialApp.router(
        title: 'Receipt Flow',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}

// GoRouter 설정
final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final authService = AuthService(auth: FirebaseAuth.instance);
    final user = authService.getCurrentUser();
    final isAuthPage = state.matchedLocation == '/login';

    // 로그인하지 않은 사용자는 로그인 페이지로
    if (user == null && !isAuthPage) {
      return '/login';
    }

    // 이미 로그인한 사용자가 로그인 페이지에 접근하면 홈으로
    if (user != null && isAuthPage) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const ReceiptListPage(),
    ),
    GoRoute(
      path: '/upload',
      builder: (context, state) => const ReceiptUploadPage(),
    ),
  ],
);

// 로그인 페이지
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService(auth: FirebaseAuth.instance);
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInAnonymously();
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '로그인 실패: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 로고/타이틀
              const Icon(
                Icons.receipt_long,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Receipt Flow',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '영수증 관리 시스템',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // 익명 로그인 버튼
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _signInAnonymously,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('익명 로그인'),
                ),

              // 에러 메시지
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Text(
                'MVP 버전 - 익명 로그인으로 시작하세요',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
