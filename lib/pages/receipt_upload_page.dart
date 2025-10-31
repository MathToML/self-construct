// @CODE:RECEIPT-002:UI | SPEC: .moai/specs/SPEC-RECEIPT-002/spec.md | TEST: test/pages/receipt_upload_page_test.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
///
/// @CODE:RECEIPT-003 - 수정 모드 추가
/// - receiptId가 있으면 수정 모드, 없으면 생성 모드
/// - 수정 모드: Firestore에서 기존 데이터 로드 후 컨트롤러에 설정
class ReceiptUploadPage extends StatefulWidget {
  final String? receiptId; // 수정 모드일 때만 값이 있음

  const ReceiptUploadPage({
    super.key,
    this.receiptId,
  });

  @override
  State<ReceiptUploadPage> createState() => _ReceiptUploadPageState();
}

class _ReceiptUploadPageState extends State<ReceiptUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _businessPurposeController = TextEditingController();

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  Uint8List? _imageBytes;
  bool _isUploading = false;
  String? _existingImageUrl; // 수정 모드: 기존 이미지 URL

  final List<String> _categories = ['식비', '교통', '숙박', '기타'];

  @override
  void initState() {
    super.initState();
    // 수정 모드: 기존 데이터 로드
    if (widget.receiptId != null) {
      _loadExistingReceipt();
    }
  }

  /// @CODE:RECEIPT-003 - 수정 모드: 기존 데이터 로드
  Future<void> _loadExistingReceipt() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('receipts')
          .doc(widget.receiptId)
          .get();

      if (!doc.exists) {
        throw Exception('영수증을 찾을 수 없습니다');
      }

      final receipt = ReceiptRecord.fromSnapshot(doc);

      setState(() {
        _amountController.text = receipt.amount.toString();
        _selectedCategory = receipt.category;
        _selectedDate = receipt.date;
        _businessPurposeController.text = receipt.businessPurpose ?? '';
        _existingImageUrl = receipt.imageUrl;
      });
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text('데이터 로드 실패: $e'),
          ),
        );
      }
    }
  }

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
        withData: true, // Web에서 bytes를 가져오기 위해 필요
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // 5MB 체크 (5 * 1024 * 1024 = 5242880 bytes)
        if (file.size > 5 * 1024 * 1024) {
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
          _imageBytes = file.bytes;
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
  Future<String> _uploadImageToStorage(Uint8List imageData, String userId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance
        .ref()
        .child('receipts')
        .child(userId)
        .child(fileName);

    await ref.putData(imageData);
    return await ref.getDownloadURL();
  }

  /// 영수증 업로드/수정
  ///
  /// 1. 폼 검증 (필수 필드)
  /// 2. 이미지 Firebase Storage 업로드
  /// 3. Firestore receipts 컬렉션에 저장/업데이트
  /// 4. 성공 시 목록 화면 또는 상세 화면으로 복귀
  ///
  /// @CODE:RECEIPT-003 - 수정 모드 추가
  /// - widget.receiptId != null이면 .update() 사용
  /// - widget.receiptId == null이면 .add() 사용
  Future<void> _uploadReceipt() async {
    // 폼 검증
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 이미지 필수 체크 (생성 모드만)
    if (_imageBytes == null && _existingImageUrl == null) {
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

      // 이미지 업로드 (새 이미지가 선택된 경우만)
      String imageUrl = _existingImageUrl ?? '';
      if (_imageBytes != null) {
        imageUrl = await _uploadImageToStorage(_imageBytes!, userId);
      }

      if (widget.receiptId != null) {
        // 수정 모드: Firestore 업데이트
        await FirebaseFirestore.instance
            .collection('receipts')
            .doc(widget.receiptId)
            .update({
          'amount': double.parse(_amountController.text),
          'category': _selectedCategory,
          'date': Timestamp.fromDate(_selectedDate),
          'businessPurpose': _businessPurposeController.text.trim().isEmpty
              ? null
              : _businessPurposeController.text.trim(),
          if (_imageBytes != null) 'imageUrl': imageUrl, // 이미지 변경 시만
        });

        if (mounted) {
          ShadToaster.of(context).show(
            const ShadToast(
              description: Text('영수증이 수정되었습니다'),
            ),
          );
          context.pop(); // 상세 화면으로 복귀
        }
      } else {
        // 생성 모드: Firestore에 새 문서 추가
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
          context.go('/'); // 목록 화면으로 복귀
        }
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
    final dateFormat = DateFormat('yyyy-MM-dd');
    final isEditMode = widget.receiptId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? '영수증 수정' : '영수증 업로드',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _existingImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: _existingImageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 64,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '이미지를 선택해주세요',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '(JPG, PNG, 5MB 이하)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
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
                const Text('카테고리*', style: TextStyle(fontSize: 14)),
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
                const Text('날짜', style: TextStyle(fontSize: 14)),
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
                        ),
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Colors.grey[600],
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

            // 업로드/수정 버튼
            ShadButton(
              onPressed: _isUploading ? null : _uploadReceipt,
              size: ShadButtonSize.lg,
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditMode ? '수정' : '업로드'),
            ),
          ],
        ),
      ),
    );
  }
}
