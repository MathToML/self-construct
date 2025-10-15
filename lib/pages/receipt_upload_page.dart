// @CODE:RECEIPT-002:UI | SPEC: .moai/specs/SPEC-RECEIPT-002/spec.md | TEST: test/pages/receipt_upload_page_test.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../services/auth_service.dart';
import '../models/receipt_record.dart';

/// 영수증 업로드 페이지
///
/// shadcn_ui 스타일: FilePicker + Firebase Storage 업로드
///
/// SPEC 요구사항:
/// - FilePicker로 이미지 선택 (JPG, PNG, 5MB 이하)
/// - 필수 필드: amount, category
/// - 선택 필드: businessPurpose
/// - DatePicker로 날짜 선택
/// - Firebase Storage 이미지 업로드
/// - Firestore receipts 컬렉션에 저장
/// - 업로드 중 버튼 비활성화 + 진행률 표시
class ReceiptUploadPage extends StatefulWidget {
  const ReceiptUploadPage({super.key});

  @override
  State<ReceiptUploadPage> createState() => _ReceiptUploadPageState();
}

class _ReceiptUploadPageState extends State<ReceiptUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _businessPurposeController = TextEditingController();

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  File? _imageFile;
  bool _isUploading = false;

  final List<String> _categories = ['식비', '교통', '숙박', '기타'];

  @override
  void dispose() {
    _amountController.dispose();
    _businessPurposeController.dispose();
    super.dispose();
  }

  /// 이미지 선택
  ///
  /// FilePicker로 JPG/PNG 이미지 선택
  /// 5MB 초과 시 에러 메시지 표시
  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final size = await file.length();

        // 5MB 체크 (5 * 1024 * 1024 = 5242880 bytes)
        if (size > 5 * 1024 * 1024) {
          if (mounted) {
            ShadToaster.of(context).show(
              const ShadToast.destructive(
                description: Text('파일 크기는 5MB를 초과할 수 없습니다'),
              ),
            );
          }
          return;
        }

        setState(() {
          _imageFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('이미지 선택 실패: $e'),
          ),
        );
      }
    }
  }

  /// 날짜 선택
  ///
  /// DatePicker로 영수증 날짜 선택 (과거 날짜만 가능)
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Firebase Storage에 이미지 업로드
  ///
  /// Returns: 업로드된 이미지 다운로드 URL
  Future<String> _uploadImageToStorage(File file, String userId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance
        .ref()
        .child('receipts')
        .child(userId)
        .child(fileName);

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// 영수증 업로드
  ///
  /// 1. 폼 검증 (필수 필드)
  /// 2. 이미지 Firebase Storage 업로드
  /// 3. Firestore receipts 컬렉션에 저장
  /// 4. 성공 시 목록 화면 복귀
  Future<void> _uploadReceipt() async {
    // 폼 검증
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 이미지 필수 체크
    if (_imageFile == null) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('이미지를 선택해주세요'),
        ),
      );
      return;
    }

    // 카테고리 필수 체크
    if (_selectedCategory == null) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('카테고리를 선택해주세요'),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final authService = AuthService(auth: FirebaseAuth.instance);
      final userId = authService.getCurrentUser();

      if (userId == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 이미지 업로드
      final imageUrl = await _uploadImageToStorage(_imageFile!, userId);

      // Firestore에 영수증 저장
      final receipt = ReceiptRecord(
        id: '', // Firestore가 자동 생성
        userId: userId,
        imageUrl: imageUrl,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        category: _selectedCategory,
        businessPurpose: _businessPurposeController.text.trim().isEmpty
            ? null
            : _businessPurposeController.text.trim(),
        createdAt: DateTime.now(),
        isSubmitted: false,
      );

      await FirebaseFirestore.instance
          .collection('receipts')
          .add(receipt.toMap());

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text('영수증이 성공적으로 업로드되었습니다'),
          ),
        );

        // 목록 화면으로 복귀
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('업로드 실패: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '영수증 업로드',
          style: theme.textTheme.h4,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 이미지 선택 버튼 및 미리보기
            GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              child: ShadCard(
                padding: EdgeInsets.zero,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: 64,
                              color: theme.colorScheme.mutedForeground,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '이미지를 선택해주세요',
                              style: theme.textTheme.muted,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '(JPG, PNG, 5MB 이하)',
                              style: theme.textTheme.small.copyWith(
                                color: theme.colorScheme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 이미지 선택 버튼
            ShadButton(
              onPressed: _isUploading ? null : _pickImage,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_file, size: 20),
                  SizedBox(width: 8),
                  Text('이미지 선택'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 금액 입력 (필수)
            ShadInputFormField(
              key: const Key('amount_field'),
              controller: _amountController,
              label: const Text('금액*'),
              placeholder: const Text('10000'),
              keyboardType: TextInputType.number,
              enabled: !_isUploading,
              validator: (value) {
                if (value.trim().isEmpty) {
                  return '금액을 입력해주세요';
                }
                if (double.tryParse(value) == null) {
                  return '올바른 금액을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 카테고리 선택 (필수)
            Column(
              key: const Key('category_field'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('카테고리*', style: theme.textTheme.small),
                const SizedBox(height: 8),
                ShadSelect<String>(
                  placeholder: const Text('카테고리 선택'),
                  options: _categories
                      .map((category) => ShadOption(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  selectedOptionBuilder: (context, value) => Text(value),
                  onChanged: _isUploading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 날짜 선택
            Column(
              key: const Key('date_field'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('날짜', style: theme.textTheme.small),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _isUploading ? null : () => _selectDate(context),
                  child: ShadCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateFormat.format(_selectedDate),
                          style: theme.textTheme.p,
                        ),
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 업무 목적 입력 (선택)
            ShadInputFormField(
              key: const Key('business_purpose_field'),
              controller: _businessPurposeController,
              label: const Text('업무 목적'),
              placeholder: const Text('팀 회식'),
              maxLines: 3,
              enabled: !_isUploading,
            ),
            const SizedBox(height: 24),

            // 업로드 버튼
            ShadButton(
              onPressed: _isUploading ? null : _uploadReceipt,
              size: ShadButtonSize.lg,
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('업로드'),
            ),
          ],
        ),
      ),
    );
  }
}
