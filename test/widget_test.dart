// Receipt Flow App 통합 테스트

import 'package:flutter_test/flutter_test.dart';
import 'package:self_construct/main.dart';

void main() {
  testWidgets('ReceiptFlowApp smoke test', (WidgetTester tester) async {
    // Firebase 초기화가 필요하므로 기본 앱 로딩 테스트만 수행
    await tester.pumpWidget(const ReceiptFlowApp());

    // 앱이 로드되는지 확인
    expect(find.byType(ReceiptFlowApp), findsOneWidget);
  });
}
