# TAG 인덱스

> 최종 업데이트: 2025-10-18

## @TAG 체계

```
@SPEC:ID → @TEST:ID → @CODE:ID → @DOC:ID
```

---

## RECEIPT-001: Receipt Upload & Basic Flow - Employee Web App MVP

### @SPEC:RECEIPT-001
- `.moai/specs/SPEC-RECEIPT-001/spec.md:26`

### @TEST:RECEIPT-001
- `test/services/auth_service_test.dart:1` - 인증 서비스 테스트
- `test/services/firestore_service_test.dart:1` - Firestore 서비스 테스트
- `test/services/storage_service_test.dart:1` - Storage 서비스 테스트
- `test/pages/receipt_list_page_test.dart:1` - 영수증 목록 페이지 테스트
- `test/pages/receipt_upload_page_test.dart:1` - 영수증 업로드 페이지 테스트
- `test/models/receipt_record_test.dart:1` - 영수증 모델 테스트

### @CODE:RECEIPT-001
- `lib/main.dart:1` - 앱 진입점
- `lib/models/receipt_record.dart:1` - 영수증 데이터 모델
- `lib/services/auth_service.dart:1` - Firebase 인증 서비스
- `lib/services/firestore_service.dart:1` - Firestore CRUD 서비스
- `lib/services/storage_service.dart:1` - Cloud Storage 서비스
- `lib/pages/receipt_list_page.dart:1` - 영수증 목록 페이지
- `lib/pages/receipt_upload_page.dart:1` - 영수증 업로드 페이지
- `storage.rules:1` - Storage 보안 규칙
- `firestore.rules:1` - Firestore 보안 규칙

### TAG 체인 무결성
✅ @SPEC → @TEST → @CODE 연결 완료
✅ 고아 TAG 없음
✅ 모든 파일 추적 가능

**버전**: v0.1.0 | **상태**: completed

---

## RECEIPT-004: 영수증 검색 및 필터링

### @SPEC:RECEIPT-004
- `.moai/specs/SPEC-RECEIPT-004/spec.md:30`

### @TEST:RECEIPT-004
- `test/utils/receipt_filter_test.dart:1` - 필터링 로직 테스트 (16개)
- `test/utils/debounce_test.dart:1` - 디바운싱 패턴 테스트 (4개)

### @CODE:RECEIPT-004
- `lib/pages/receipts/receipt_search_page.dart:1` - 검색 페이지 UI (231 LOC)
- `lib/widgets/receipt_filter_widget.dart:1` - 필터 위젯 (207 LOC)
- `lib/utils/receipt_filter.dart:1` - 필터링 로직 (95 LOC)
- `lib/utils/debounce.dart:1` - 디바운싱 유틸리티 (25 LOC)
- `lib/services/firestore_service.dart:74` - 검색 쿼리 메서드 (+25 LOC)

### TAG 체인 무결성
✅ @SPEC → @TEST → @CODE 연결 완료
✅ 고아 TAG 없음
✅ 모든 파일 추적 가능

**버전**: v0.1.0 | **상태**: completed

---

## 전체 SPEC 진행률

| SPEC ID | 상태 | 버전 | TAG 체인 | 테스트 | 코드 파일 |
|---------|------|------|----------|--------|----------|
| RECEIPT-001 | completed | 0.1.0 | ✅ | 6개 | 9개 |
| RECEIPT-004 | completed | 0.1.0 | ✅ | 2개 (20 tests) | 5개 |

**총 2개 SPEC, 모두 완료 (100%)**

---

## TAG 검증 명령어

### 전체 TAG 스캔
```bash
rg '@(SPEC|TEST|CODE):RECEIPT-' -n lib/ test/ .moai/specs/
```

### 특정 SPEC TAG 조회
```bash
# RECEIPT-001
rg '@(SPEC|TEST|CODE):RECEIPT-001' -n

# RECEIPT-004
rg '@(SPEC|TEST|CODE):RECEIPT-004' -n
```

### 고아 TAG 감지
```bash
# CODE는 있는데 SPEC이 없는 경우
rg '@CODE:RECEIPT-' -n lib/ | while read line; do
  id=$(echo $line | grep -o 'RECEIPT-[0-9]\+')
  rg -q "@SPEC:$id" .moai/specs/ || echo "고아 CODE TAG: $id"
done
```

---

**마지막 검증**: 2025-10-18
**검증 결과**: 모든 TAG 체인 무결성 확인 완료 ✅
