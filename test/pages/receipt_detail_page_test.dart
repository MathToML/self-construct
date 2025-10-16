// @TEST:RECEIPT-003 | SPEC: .moai/specs/SPEC-RECEIPT-003/spec.md

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:self_construct/pages/receipt_detail_page.dart';
import 'package:self_construct/models/receipt_record.dart';

@GenerateMocks([FirebaseFirestore, FirebaseStorage, CollectionReference, DocumentReference, DocumentSnapshot])
import 'receipt_detail_page_test.mocks.dart';

void main() {
  group('ReceiptDetailPage Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
    });

    testWidgets('페이지가 정상적으로 렌더링되어야 한다', (WidgetTester tester) async {
      // Given: 영수증 데이터
      final receiptData = {
        'userId': 'test_user',
        'imageUrl': 'https://example.com/receipt.jpg',
        'amount': 10000.0,
        'date': Timestamp.fromDate(DateTime(2025, 10, 16)),
        'category': '식비',
        'businessPurpose': '팀 회식',
        'createdAt': Timestamp.fromDate(DateTime(2025, 10, 16)),
        'isSubmitted': false,
      };

      when(mockFirestore.collection('receipts')).thenReturn(mockCollection);
      when(mockCollection.doc('test_receipt_id')).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.id).thenReturn('test_receipt_id');
      when(mockDocSnapshot.data()).thenReturn(receiptData);

      // When: 페이지 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: ReceiptDetailPage(receiptId: 'test_receipt_id'),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 영수증 정보가 표시되어야 함
      expect(find.text('영수증 상세'), findsOneWidget);
      expect(find.text('₩10,000'), findsOneWidget);
      expect(find.text('팀 회식'), findsOneWidget);
    });

    testWidgets('제출 전 영수증: 수정/삭제/제출 버튼이 표시되어야 한다', (WidgetTester tester) async {
      // Given: 제출 전 영수증 (isSubmitted: false)
      final receiptData = {
        'userId': 'test_user',
        'imageUrl': 'https://example.com/receipt.jpg',
        'amount': 10000.0,
        'date': Timestamp.fromDate(DateTime(2025, 10, 16)),
        'category': '식비',
        'businessPurpose': '팀 회식',
        'createdAt': Timestamp.fromDate(DateTime(2025, 10, 16)),
        'isSubmitted': false,
      };

      when(mockFirestore.collection('receipts')).thenReturn(mockCollection);
      when(mockCollection.doc('test_receipt_id')).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.id).thenReturn('test_receipt_id');
      when(mockDocSnapshot.data()).thenReturn(receiptData);

      // When: 페이지 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: ReceiptDetailPage(receiptId: 'test_receipt_id'),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 버튼 3개가 표시되어야 함
      expect(find.text('수정'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
      expect(find.text('제출'), findsOneWidget);
    });

    testWidgets('제출 후 영수증: 버튼 비활성화 및 안내 메시지가 표시되어야 한다', (WidgetTester tester) async {
      // Given: 제출 후 영수증 (isSubmitted: true)
      final receiptData = {
        'userId': 'test_user',
        'imageUrl': 'https://example.com/receipt.jpg',
        'amount': 10000.0,
        'date': Timestamp.fromDate(DateTime(2025, 10, 16)),
        'category': '식비',
        'businessPurpose': '팀 회식',
        'createdAt': Timestamp.fromDate(DateTime(2025, 10, 16)),
        'isSubmitted': true,
      };

      when(mockFirestore.collection('receipts')).thenReturn(mockCollection);
      when(mockCollection.doc('test_receipt_id')).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.id).thenReturn('test_receipt_id');
      when(mockDocSnapshot.data()).thenReturn(receiptData);

      // When: 페이지 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: ReceiptDetailPage(receiptId: 'test_receipt_id'),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 안내 메시지가 표시되어야 함
      expect(find.text('이미 제출된 영수증입니다'), findsOneWidget);
      expect(find.text('수정'), findsNothing);
      expect(find.text('삭제'), findsNothing);
      expect(find.text('제출'), findsNothing);
    });

    testWidgets('이미지 로딩 중에는 로딩 인디케이터가 표시되어야 한다', (WidgetTester tester) async {
      // Given: Firestore가 아직 응답하지 않음
      when(mockFirestore.collection('receipts')).thenReturn(mockCollection);
      when(mockCollection.doc('test_receipt_id')).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) => Future.delayed(
            const Duration(seconds: 2),
            () => mockDocSnapshot,
          ));

      // When: 페이지 렌더링
      await tester.pumpWidget(
        MaterialApp(
          home: ReceiptDetailPage(receiptId: 'test_receipt_id'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Then: 로딩 인디케이터가 표시되어야 함
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
