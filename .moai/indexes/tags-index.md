# TAG 인덱스

> 최종 업데이트: 2025-10-16

## @TAG 체계

```
@SPEC:ID → @TEST:ID → @CODE:ID → @DOC:ID
```

---

## RECEIPT-003: 영수증 상세 보기 및 CRUD

### @SPEC:RECEIPT-003
- `.moai/specs/SPEC-RECEIPT-003/spec.md:27`

### @TEST:RECEIPT-003
- `test/pages/receipt_detail_page_test.dart:1` - 영수증 상세 페이지 위젯 테스트
- `test/models/receipt_record_test.dart:57` - copyWith 메서드 테스트

### @CODE:RECEIPT-003
- `lib/pages/receipt_detail_page.dart:1` - 영수증 상세 보기 화면 (506 LOC)
- `lib/pages/receipt_upload_page.dart:28,65,186` - 수정 모드 추가
- `lib/models/receipt_record.dart:60` - copyWith 메서드
- `lib/widgets/receipt_card.dart:20,47` - 클릭 이벤트
- `lib/main.dart:12,71,79` - GoRouter 라우트 설정

### TAG 체인 무결성
✅ @SPEC → @TEST → @CODE 연결 완료
✅ 고아 TAG 없음
✅ 모든 파일 추적 가능

---

## 전체 SPEC 진행률

| SPEC ID | 상태 | 버전 | TAG 체인 |
|---------|------|------|----------|
| RECEIPT-001 | completed | 1.0.0 | ✅ |
| RECEIPT-002 | completed | 1.0.0 | ✅ |
| RECEIPT-003 | completed | 0.1.0 | ✅ |

**총 3개 SPEC, 모두 완료 (100%)**
