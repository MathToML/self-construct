---
id: RECEIPT-001
version: 0.0.1
status: draft
created: 2025-10-14
updated: 2025-10-14
author: @edward
priority: high
category: feature
labels:
  - flutter
  - firebase
  - receipt-management
  - mvp
scope:
  packages:
    - lib/pages/receipts
    - lib/services
    - lib/models
  files:
    - receipt_upload_page.dart
    - firestore_service.dart
    - receipt_record.dart
---

# @SPEC:RECEIPT-001: Receipt Upload & Basic Flow - Employee Web App MVP

## HISTORY

### v0.0.1 (2025-10-14)
- **INITIAL**: Receipt Upload & Basic Flow MVP 명세 최초 작성
- **AUTHOR**: @edward
- **SCOPE**: Flutter Web + Firebase 기반 영수증 업로드 및 관리 시스템
- **TECH STACK**: Flutter 3.24+, shadcn_flutter, Firebase (Firestore/Auth/Storage)
- **ARCHITECTURE**: FlutterFlow 스타일 Record/Snapshot 패턴
- **TARGET**: 직원이 영수증을 업로드하고 제출하며, 제출 이력을 실시간 조회할 수 있는 MVP

---

## 1. Environment (환경 및 전제조건)

### 기술 환경
- **Frontend**: Flutter Web 3.24+
- **UI Framework**: shadcn_flutter (Radix-like Flutter UI library)
- **Backend**: Firebase Platform
  - **Authentication**: Firebase Auth (이메일/비밀번호)
  - **Database**: Cloud Firestore
  - **Storage**: Firebase Storage
  - **Functions**: Cloud Functions (추후 확장)
- **개발 환경**: Firebase Emulator Suite (로컬 개발)

### Firebase 프로젝트 구조
```
Firebase Project: receipt-flow-test

Firestore Database:
  └── receipts/
      └── {receiptId}
          ├── userId: string
          ├── imageUrl: string
          ├── amount: number
          ├── date: timestamp
          ├── category: string (optional)
          ├── businessPurpose: string (optional)
          ├── createdAt: timestamp
          └── isSubmitted: boolean

Storage:
  └── receipts/
      └── {userId}/
          └── {receiptId}/
              └── image.{ext}

Authentication:
  └── Email/Password Provider
```

### 아키텍처 패턴: FlutterFlow Record/Snapshot

FlutterFlow에서 사용하는 타입 안전 데이터 패턴을 적용:

```dart
// 1. Record 클래스 정의 (Typed Model)
class ReceiptRecord {
  final String id;
  final String userId;
  final String imageUrl;
  final double amount;
  final DateTime date;
  final String? category;
  final String? businessPurpose;
  final DateTime createdAt;
  final bool isSubmitted;

  ReceiptRecord({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.amount,
    required this.date,
    this.category,
    this.businessPurpose,
    required this.createdAt,
    required this.isSubmitted,
  });

  // 2. Snapshot → Record 변환
  factory ReceiptRecord.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ReceiptRecord(
      id: snapshot.id,
      userId: data['userId'] as String,
      imageUrl: data['imageUrl'] as String,
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] as String?,
      businessPurpose: data['businessPurpose'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isSubmitted: data['isSubmitted'] as bool? ?? false,
    );
  }

  // 3. Record → Map (Firestore 저장용)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'businessPurpose': businessPurpose,
      'createdAt': Timestamp.fromDate(createdAt),
      'isSubmitted': isSubmitted,
    };
  }
}

// 4. StreamBuilder에서 사용
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('receipts')
      .where('userId', isEqualTo: currentUserId)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();

    final receipts = snapshot.data!.docs
        .map((doc) => ReceiptRecord.fromSnapshot(doc))
        .toList();

    return ListView.builder(
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final receipt = receipts[index];
        return ReceiptListItem(receipt: receipt);
      },
    );
  },
)
```

### 네트워크 및 인프라 가정
- 브라우저: 최신 Chrome, Safari, Edge (모던 웹 브라우저)
- 네트워크: 온라인 연결 필수 (오프라인 지원은 Phase 2)
- Firebase 프로젝트: `receipt-flow-test` (GCP 기본 리전: asia-northeast1)

---

## 2. Assumptions (전제 조건)

### 사용자 인증
- 모든 사용자는 Firebase Authentication으로 인증되어야 함
- 인증되지 않은 사용자는 로그인 페이지로 리다이렉트
- 사용자 세션은 Firebase Auth SDK가 자동 관리

### 데이터 정합성
- 영수증 ID는 Firestore가 자동 생성 (auto-generated document ID)
- userId는 Firebase Auth의 `currentUser.uid`와 일치
- createdAt은 서버 타임스탬프(`FieldValue.serverTimestamp()`) 사용

### 파일 제약
- 업로드 파일 크기: 10MB 이하
- 허용 형식: JPG, PNG, PDF
- 파일명 충돌 방지: `{userId}/{receiptId}/{timestamp}_image.{ext}` 패턴

### 보안 가정
- Firestore 보안 규칙: 사용자는 본인의 영수증만 읽기/쓰기 가능
- Storage 보안 규칙: 파일 크기 및 MIME 타입 검증
- Cloud Functions: Admin SDK를 통한 서버 측 검증 (추후 확장)

---

## 3. Requirements (기능 요구사항 - EARS 방식)

### 3.1. Ubiquitous Requirements (기본 요구사항)
- 시스템은 직원이 영수증 이미지를 업로드할 수 있는 기능을 제공해야 한다
- 시스템은 영수증 기본 정보(날짜, 금액, 카테고리, 비즈니스 목적)를 입력받아야 한다
- 시스템은 제출된 영수증 목록을 실시간으로 조회할 수 있어야 한다
- 시스템은 Firebase Authentication을 통한 직원 인증 기능을 제공해야 한다
- 시스템은 shadcn_flutter UI 컴포넌트를 사용하여 일관된 디자인을 제공해야 한다

### 3.2. Event-driven Requirements (이벤트 기반 요구사항)
- WHEN 직원이 영수증 이미지를 업로드하면, 시스템은 Firebase Storage에 파일을 업로드하고 다운로드 URL을 반환해야 한다
- WHEN 직원이 영수증 제출을 완료하면, 시스템은 Firestore `receipts` 컬렉션에 문서를 생성하고 확인 메시지를 표시해야 한다
- WHEN 업로드된 파일 크기가 10MB를 초과하면, 시스템은 에러 메시지를 반환하고 업로드를 차단해야 한다
- WHEN Firestore 데이터가 변경되면, 시스템은 StreamBuilder를 통해 UI를 자동으로 업데이트해야 한다
- WHEN 파일 업로드가 진행 중이면, 시스템은 진행률 표시(progress indicator)를 표시해야 한다
- WHEN 사용자가 로그아웃하면, 시스템은 Firebase Auth 세션을 종료하고 로그인 페이지로 이동해야 한다

### 3.3. State-driven Requirements (상태 기반 요구사항)
- WHILE 영수증이 작성 중일 때, 시스템은 로컬 상태 관리(StatefulWidget)를 통해 입력 데이터를 보관해야 한다
- WHILE 영수증이 제출된 후(`isSubmitted: true`), 직원은 해당 영수증을 수정할 수 없어야 한다
- WHILE 사용자가 인증되지 않은 상태일 때, 시스템은 로그인 페이지로 리다이렉트해야 한다
- WHILE 네트워크 연결이 불안정할 때, 시스템은 재시도 로직을 제공해야 한다 (Firebase SDK 자동 처리)

### 3.4. Optional Features (선택적 기능)
- WHERE 영수증에 카테고리가 지정되면, 시스템은 카테고리별 필터링을 제공할 수 있다
- WHERE 영수증이 아직 제출되지 않았으면(`isSubmitted: false`), 시스템은 임시 저장 기능을 제공할 수 있다
- WHERE OCR API가 연동되면, 시스템은 영수증 이미지에서 자동으로 금액과 날짜를 추출할 수 있다 (Phase 2)

### 3.5. Constraints (제약사항)
- IF 필수 필드(날짜, 금액)가 누락되면, 시스템은 제출을 차단하고 에러 메시지를 표시해야 한다
- 영수증 이미지는 JPG, PNG, PDF 형식만 허용해야 한다
- 업로드 파일 크기는 10MB 이하로 제한해야 한다
- Firebase Firestore 보안 규칙을 통해 사용자는 본인의 영수증만 조회/수정 가능해야 한다
- IF 잘못된 파일 형식이 업로드되면, 시스템은 에러 메시지를 반환하고 업로드를 차단해야 한다
- 금액은 0보다 큰 양수여야 하며, 소수점 둘째 자리까지만 허용해야 한다

---

## 4. Specifications (상세 명세)

### 4.1. Flutter Web 구조

```
lib/
├── main.dart                       # App Entry Point, Firebase 초기화
├── firebase_options.dart           # FlutterFire CLI 자동 생성
│
├── pages/
│   ├── auth/
│   │   ├── login_page.dart         # 로그인 페이지
│   │   └── register_page.dart      # 회원가입 페이지 (선택)
│   │
│   └── receipts/
│       ├── receipt_upload_page.dart    # 영수증 업로드 페이지
│       ├── receipt_list_page.dart      # 영수증 목록 페이지
│       └── receipt_detail_page.dart    # 영수증 상세 페이지
│
├── models/
│   └── receipt_record.dart         # ReceiptRecord 모델 (Record/Snapshot 패턴)
│
├── services/
│   ├── auth_service.dart           # Firebase Auth 서비스
│   ├── firestore_service.dart      # Firestore CRUD 서비스
│   └── storage_service.dart        # Firebase Storage 업로드 서비스
│
└── widgets/
    ├── receipt_card.dart           # 영수증 카드 컴포넌트
    └── file_picker_button.dart     # 파일 선택 버튼 (shadcn_flutter)
```

### 4.2. Firestore 데이터 스키마

**Collection: `receipts`**

| 필드명           | 타입      | 필수 | 설명                          |
|------------------|-----------|------|-------------------------------|
| userId           | string    | ✅    | Firebase Auth UID             |
| imageUrl         | string    | ✅    | Firebase Storage 다운로드 URL |
| amount           | number    | ✅    | 금액 (double, ≥ 0.01)         |
| date             | timestamp | ✅    | 영수증 발행 날짜              |
| category         | string    | ❌    | 카테고리 (예: "식비", "교통") |
| businessPurpose  | string    | ❌    | 비즈니스 목적 설명            |
| createdAt        | timestamp | ✅    | 문서 생성 시간 (서버 타임스탬프) |
| isSubmitted      | boolean   | ✅    | 제출 여부 (기본값: false)     |

**인덱스 (추천)**:
- `userId` + `createdAt` (DESC): 사용자별 최신 영수증 조회 최적화
- `userId` + `isSubmitted` + `createdAt` (DESC): 제출 상태별 필터링

### 4.3. Firebase Storage 구조

```
gs://receipt-flow-test.appspot.com/
  └── receipts/
      └── {userId}/              # 사용자별 디렉토리
          └── {receiptId}/       # 영수증별 디렉토리
              └── image.{ext}    # 원본 이미지 파일
```

**파일 명명 규칙**:
- `{userId}`: Firebase Auth UID
- `{receiptId}`: Firestore 문서 ID (자동 생성)
- `{ext}`: jpg, png, pdf

### 4.4. Firebase 보안 규칙

**Firestore Security Rules**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 영수증 컬렉션: 본인 영수증만 읽기/쓰기 가능
    match /receipts/{receiptId} {
      allow read: if request.auth != null
                  && request.auth.uid == resource.data.userId;

      allow create: if request.auth != null
                    && request.auth.uid == request.resource.data.userId
                    && request.resource.data.amount is number
                    && request.resource.data.amount > 0
                    && request.resource.data.imageUrl is string
                    && request.resource.data.date is timestamp;

      allow update: if request.auth != null
                    && request.auth.uid == resource.data.userId
                    && resource.data.isSubmitted == false;  // 제출 전에만 수정 가능

      allow delete: if request.auth != null
                    && request.auth.uid == resource.data.userId
                    && resource.data.isSubmitted == false;  // 제출 전에만 삭제 가능
    }
  }
}
```

**Storage Security Rules**:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /receipts/{userId}/{receiptId}/{fileName} {
      // 업로드: 본인만 가능, 파일 크기 및 타입 검증
      allow write: if request.auth != null
                   && request.auth.uid == userId
                   && request.resource.size < 10 * 1024 * 1024  // 10MB
                   && request.resource.contentType.matches('image/(jpeg|png)|application/pdf');

      // 다운로드: 본인만 가능
      allow read: if request.auth != null
                  && request.auth.uid == userId;
    }
  }
}
```

### 4.5. 핵심 기능 플로우

**1. 영수증 업로드 플로우**:
```
1. 사용자가 파일 선택 (file_picker_web 사용)
   ↓
2. 파일 검증 (크기, 형식)
   ↓
3. Storage 업로드 시작 (putData)
   → UploadTask.snapshotEvents.listen((progress) => UI 업데이트)
   ↓
4. 업로드 완료 → getDownloadURL()
   ↓
5. UI에 미리보기 표시 (CachedNetworkImage)
```

**2. 영수증 제출 플로우**:
```
1. 필수 필드 검증 (날짜, 금액)
   ↓
2. ReceiptRecord 객체 생성
   ↓
3. Firestore.collection('receipts').add(receipt.toMap())
   ↓
4. isSubmitted: true 업데이트
   ↓
5. 성공 메시지 표시 + 목록 페이지로 이동
```

**3. 실시간 목록 조회 플로우**:
```
1. StreamBuilder 초기화
   → FirebaseFirestore.instance
       .collection('receipts')
       .where('userId', isEqualTo: currentUserId)
       .orderBy('createdAt', descending: true)
       .snapshots()
   ↓
2. QuerySnapshot → List<ReceiptRecord> 변환
   ↓
3. ListView.builder로 렌더링
   ↓
4. Firestore 변경 감지 → 자동 UI 업데이트
```

### 4.6. 에러 처리 전략

**Firebase 예외 처리**:
```dart
try {
  await FirebaseFirestore.instance.collection('receipts').add(data);
} on FirebaseException catch (e) {
  switch (e.code) {
    case 'permission-denied':
      showError('접근 권한이 없습니다.');
      break;
    case 'unavailable':
      showError('네트워크 연결을 확인해주세요.');
      break;
    default:
      showError('오류가 발생했습니다: ${e.message}');
  }
} catch (e) {
  showError('알 수 없는 오류가 발생했습니다.');
}
```

**파일 업로드 에러**:
- 크기 초과 → "파일 크기는 10MB 이하여야 합니다."
- 형식 오류 → "JPG, PNG, PDF 파일만 업로드 가능합니다."
- 네트워크 오류 → "업로드 실패. 네트워크 연결을 확인해주세요."

---

## 5. Traceability (@TAG 추적성)

### TAG 체인
```
@SPEC:RECEIPT-001
  ↓
@TEST:RECEIPT-001
  - tests/receipts/receipt_upload_test.dart
  - tests/receipts/firestore_service_test.dart
  - tests/receipts/storage_service_test.dart
  - tests/security/firestore_rules_test.dart
  ↓
@CODE:RECEIPT-001
  - lib/pages/receipts/receipt_upload_page.dart
  - lib/pages/receipts/receipt_list_page.dart
  - lib/services/firestore_service.dart
  - lib/services/storage_service.dart
  - lib/models/receipt_record.dart
  ↓
@DOC:RECEIPT-001
  - docs/architecture/firebase-integration.md
  - docs/user-guide/receipt-upload.md
```

### 코드 내 TAG 예시

**src/models/receipt_record.dart**:
```dart
// @CODE:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md | TEST: tests/receipts/receipt_record_test.dart
class ReceiptRecord {
  // FlutterFlow 스타일 Record/Snapshot 패턴 구현
  // ...
}
```

**tests/receipts/firestore_service_test.dart**:
```dart
// @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
void main() {
  group('FirestoreService - Receipt CRUD', () {
    // Firebase Emulator 기반 테스트
  });
}
```

---

## 6. Non-Functional Requirements (비기능 요구사항)

### 성능
- 영수증 목록 로딩 시간: 1초 이내 (10개 문서 기준)
- 파일 업로드 시간: 3MB 기준 5초 이내 (네트워크 속도 의존)
- Firestore 실시간 업데이트 지연: 200ms 이내

### 보안
- 모든 통신은 HTTPS로 암호화
- Firebase Auth 토큰 검증 (자동)
- Firestore/Storage 보안 규칙 강제 적용
- 사용자 입력 검증 (클라이언트 + 보안 규칙)

### 접근성
- shadcn_flutter 컴포넌트의 기본 접근성 지원
- 키보드 네비게이션 지원
- 스크린 리더 호환 (Semantics 위젯 활용)

### 확장성
- Firestore 인덱스 최적화 (userId + createdAt)
- Cloud Functions 연동 준비 (서버 측 검증, OCR 처리)
- 다국어 지원 준비 (i18n 구조)

---

## 7. 구현 우선순위

### Phase 1: Core MVP (이번 SPEC 범위)
1. Firebase 초기화 및 Authentication
2. Storage 업로드 기능
3. Firestore CRUD 기능
4. 영수증 업로드 페이지 (shadcn_flutter)
5. 영수증 목록 페이지 (실시간 조회)

### Phase 2: 추후 확장
- OCR 자동 추출 (Cloud Vision API)
- 오프라인 지원 (Firestore Offline Persistence)
- 영수증 승인 워크플로우 (매니저 승인)
- 통계 및 대시보드

---

## 8. 참고 자료

### Firebase 공식 문서
- [FlutterFire Overview](https://firebase.flutter.dev/)
- [Firestore Data Model](https://firebase.google.com/docs/firestore/data-model)
- [Storage Security Rules](https://firebase.google.com/docs/storage/security)

### FlutterFlow 패턴 참고
- [FlutterFlow Backend Query Docs](https://docs.flutterflow.io/data-and-backend/firebase/firestore/backend-query)
- [Record/Snapshot Pattern Best Practices](https://docs.flutterflow.io/data-and-backend/firebase/firestore/data-types)

### shadcn_flutter
- [GitHub Repository](https://github.com/nank1ro/flutter-shadcn-ui)
- [Component Storybook](https://flutter-shadcn-ui.mariuti.com/)

---

**다음 단계**: `/alfred:2-build SPEC-RECEIPT-001` 실행하여 TDD 구현 시작
