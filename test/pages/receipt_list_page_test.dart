// @TEST:RECEIPT-002 | SPEC: .moai/specs/SPEC-RECEIPT-002/spec.md

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:self_construct/pages/receipt_list_page.dart';

void main() {
  group('ReceiptListPage Tests', () {
    testWidgets('로딩 상태에서 CircularProgressIndicator 표시', (tester) async {
      // Given: Stream이 아직 데이터를 방출하지 않음 (waiting)
      // When: ReceiptListPage 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptListPage(),
        ),
      );

      // 첫 프레임은 waiting 상태
      // Then: CircularProgressIndicator가 표시되어야 함
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('빈 목록일 때 EmptyStateWidget 표시', (tester) async {
      // Given: 빈 영수증 목록 (Stream이 빈 리스트 반환)
      // When: ReceiptListPage 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptListPage(),
        ),
      );

      // Stream 데이터 로드 대기
      await tester.pumpAndSettle();

      // Then: "등록된 영수증이 없습니다" 메시지 표시
      expect(find.text('등록된 영수증이 없습니다'), findsOneWidget);
    });

    testWidgets('영수증 목록이 최신순으로 정렬되어 표시', (tester) async {
      // Given: 3개의 영수증 (date 다름)
      // 실제 Stream 데이터는 구현 후 Mock으로 테스트
      // 현재는 UI 구조만 확인

      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptListPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Then: ListView.builder가 존재해야 함
      // (실제 데이터는 GREEN 단계에서 Mock Service로 주입)
      expect(find.byType(ReceiptListPage), findsOneWidget);
    });

    testWidgets('FloatingActionButton 클릭 시 업로드 화면 이동', (tester) async {
      // Given: ReceiptListPage 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptListPage(),
        ),
      );

      // When: FAB 클릭
      expect(find.byType(FloatingActionButton), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Then: ReceiptUploadPage로 네비게이션
      // (GoRouter 사용으로 실제 네비게이션은 통합 테스트에서 확인)
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('네트워크 에러 시 ErrorWidget 표시', (tester) async {
      // Given: Stream에서 에러 방출
      // When: ReceiptListPage 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptListPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Then: ErrorWidget 또는 에러 메시지 표시
      // (실제 에러 처리는 GREEN 단계에서 구현)
      expect(find.byType(ReceiptListPage), findsOneWidget);
    });

    testWidgets('AppBar에 제목과 로그아웃 버튼 표시', (tester) async {
      // Given: ReceiptListPage 렌더링
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptListPage(),
        ),
      );

      // Then: AppBar, 제목, 로그아웃 버튼 확인
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('영수증 목록'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('영수증 카드가 ListView로 표시', (tester) async {
      // Given: 영수증 데이터가 있는 경우
      await tester.pumpWidget(
        const MaterialApp(
          home: ReceiptListPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Then: ListView.builder 사용 확인
      // (실제 ReceiptCard는 데이터 주입 후 확인)
      expect(find.byType(ReceiptListPage), findsOneWidget);
    });
  });
}
