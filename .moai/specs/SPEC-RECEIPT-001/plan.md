# SPEC-RECEIPT-001 구현 계획서 (Implementation Plan)

> **Receipt Upload & Basic Flow - Employee Web App MVP**
>
> Flutter Web + Firebase 기반 영수증 관리 시스템 TDD 구현 계획

---

## 1. Overview (개요)

### 목표
Flutter Web 환경에서 Firebase를 백엔드로 활용하여 직원이 영수증을 업로드하고 관리할 수 있는 MVP를 구현합니다.

### 핵심 가치
- **SPEC-First TDD**: spec.md 요구사항 기반 테스트 작성
- **FlutterFlow 패턴**: Record/Snapshot 타입 안전 패턴 적용
- **Firebase Emulator**: 로컬 개발 환경 구축
- **Real-time UI**: StreamBuilder 기반 실시간 데이터 동기화

### 기술 스택 확정
- **Flutter**: 3.24.5 (최신 안정 버전)
- **Firebase Core**: ^3.9.0
- **Cloud Firestore**: ^5.6.0
- **Firebase Auth**: ^5.3.3
- **Firebase Storage**: ^12.3.8
- **shadcn_flutter**: ^0.6.0 (UI 컴포넌트)
- **file_picker**: ^8.1.6 (Web 파일 선택)

---

## 2. TDD Implementation Plan (RED-GREEN-REFACTOR)

### 2.1. RED Phase: 실패하는 테스트 작성

**원칙**:
- SPEC 요구사항을 테스트 케이스로 변환
- Firebase Emulator 환경에서 테스트 실행
- 각 테스트는 실패 확인 후 다음 단계 진행

**테스트 작성 순서**:

1. **모델 테스트** (`tests/models/receipt_record_test.dart`):
   ```dart
   // @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
   test('ReceiptRecord.fromSnapshot은 Firestore DocumentSnapshot을 올바르게 파싱해야 한다', () {
     // Given: Mock DocumentSnapshot
     // When: ReceiptRecord.fromSnapshot(snapshot)
     // Then: 모든 필드가 정확히 매핑됨
   });

   test('ReceiptRecord.toMap은 Firestore 저장 형식으로 변환해야 한다', () {
     // Given: ReceiptRecord 객체
     // When: record.toMap()
     // Then: Map<String, dynamic> 반환, Timestamp 타입 확인
   });
   ```

2. **Storage Service 테스트** (`tests/services/storage_service_test.dart`):
   ```dart
   // @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
   test('파일 업로드 시 10MB 초과하면 예외를 던져야 한다', () async {
     // Given: 11MB 크기 파일
     // When: uploadReceiptImage(largeFile)
     // Then: FileTooLargeException 발생
   });

   test('허용되지 않은 파일 형식은 거부해야 한다', () async {
     // Given: .txt 파일
     // When: uploadReceiptImage(invalidFile)
     // Then: InvalidFileTypeException 발생
   });

   test('정상 업로드 시 다운로드 URL을 반환해야 한다', () async {
     // Given: 유효한 JPG 파일
     // When: uploadReceiptImage(validFile)
     // Then: Firebase Storage URL 반환
   });
   ```

3. **Firestore Service 테스트** (`tests/services/firestore_service_test.dart`):
   ```dart
   // @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
   test('영수증 생성 시 필수 필드가 누락되면 예외를 던져야 한다', () async {
     // Given: amount 필드 누락
     // When: createReceipt(invalidData)
     // Then: MissingRequiredFieldException 발생
   });

   test('본인 영수증만 조회할 수 있어야 한다', () async {
     // Given: User A로 로그인
     // When: getReceipts(userA.uid)
     // Then: User A의 영수증만 반환
   });

   test('제출된 영수증은 수정할 수 없어야 한다', () async {
     // Given: isSubmitted = true인 영수증
     // When: updateReceipt(submittedReceipt)
     // Then: PermissionDeniedException 발생
   });
   ```

4. **보안 규칙 테스트** (`tests/security/firestore_rules_test.dart`):
   ```dart
   // @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
   test('인증되지 않은 사용자는 영수증을 읽을 수 없어야 한다', () async {
     // Given: 로그아웃 상태
     // When: Firestore.collection('receipts').get()
     // Then: permission-denied 에러
   });

   test('다른 사용자의 영수증을 읽으려 하면 거부해야 한다', () async {
     // Given: User A로 로그인
     // When: User B의 영수증 조회
     // Then: permission-denied 에러
   });
   ```

5. **위젯 통합 테스트** (`tests/pages/receipt_upload_page_test.dart`):
   ```dart
   // @TEST:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
   testWidgets('파일 선택 버튼을 클릭하면 파일 선택 다이얼로그가 열려야 한다', (tester) async {
     // Given: ReceiptUploadPage 렌더링
     // When: 파일 선택 버튼 탭
     // Then: FilePicker 호출 확인
   });

   testWidgets('필수 필드 누락 시 제출 버튼이 비활성화되어야 한다', (tester) async {
     // Given: amount 필드 비어있음
     // When: 제출 버튼 확인
     // Then: 버튼 disabled 상태
   });
   ```

### 2.2. GREEN Phase: 최소 구현

**원칙**:
- 테스트를 통과하는 최소한의 코드만 작성
- 중복 제거나 최적화는 REFACTOR 단계에서 수행
- SPEC 요구사항을 충족하는지 확인

**구현 순서**:

1. **Firebase 초기화** (`lib/main.dart`):
   ```dart
   // @CODE:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
     runApp(MyApp());
   }
   ```

2. **ReceiptRecord 모델** (`lib/models/receipt_record.dart`):
   - FlutterFlow 스타일 fromSnapshot, toMap 구현
   - Timestamp ↔ DateTime 변환 로직
   - Null safety 처리

3. **StorageService** (`lib/services/storage_service.dart`):
   - 파일 크기 검증 (10MB)
   - MIME 타입 검증 (image/jpeg, image/png, application/pdf)
   - Firebase Storage 업로드 (putData)
   - UploadTask 진행률 스트림 반환

4. **FirestoreService** (`lib/services/firestore_service.dart`):
   - CRUD 메서드 구현 (createReceipt, getReceipts, updateReceipt)
   - userId 필터링
   - FieldValue.serverTimestamp() 사용
   - Stream<List<ReceiptRecord>> 반환

5. **ReceiptUploadPage** (`lib/pages/receipts/receipt_upload_page.dart`):
   - shadcn_flutter Input, Button, DatePicker 컴포넌트 사용
   - StatefulWidget 상태 관리
   - 파일 선택 → 업로드 → Firestore 저장 플로우
   - 에러 처리 및 로딩 상태 표시

6. **ReceiptListPage** (`lib/pages/receipts/receipt_list_page.dart`):
   - StreamBuilder<List<ReceiptRecord>> 사용
   - ListView.builder 렌더링
   - shadcn_flutter Card 컴포넌트

### 2.3. REFACTOR Phase: 코드 품질 개선

**원칙**:
- SPEC 요구사항 충족 상태 유지
- 테스트 통과 상태 유지
- TRUST 5원칙 적용

**리팩토링 항목**:

1. **타입 안전성 강화**:
   - Result 타입 도입 (Success/Failure)
   - 예외 대신 타입 안전한 에러 처리
   - Freezed 패키지 고려 (불변 데이터 클래스)

2. **코드 중복 제거**:
   - 공통 위젯 추출 (LoadingIndicator, ErrorMessage)
   - 공통 검증 로직 추출 (Validator 클래스)

3. **성능 최적화**:
   - StreamBuilder 불필요한 재빌드 방지
   - CachedNetworkImage로 이미지 캐싱
   - Firestore 쿼리 인덱스 최적화

4. **보안 강화**:
   - 클라이언트 측 입력 검증 추가
   - Firebase 보안 규칙 단위 테스트 추가
   - 민감 정보 로깅 제거

5. **TDD 이력 주석 추가**:
   ```dart
   // @CODE:RECEIPT-001 | SPEC: SPEC-RECEIPT-001.md
   // TDD History:
   // - RED: tests/services/firestore_service_test.dart (2025-10-14)
   // - GREEN: CRUD 메서드 최소 구현 (2025-10-14)
   // - REFACTOR: Result 타입 도입, 에러 핸들링 개선 (2025-10-15)
   class FirestoreService {
     // ...
   }
   ```

---

## 3. Module Implementation Order (모듈 구현 순서)

### Priority 1: 인프라 계층 (Infrastructure Layer)
**목표**: Firebase 연결 및 기본 서비스 구축

1. **Firebase 초기화**:
   - FlutterFire CLI로 `firebase_options.dart` 생성
   - Firebase Emulator 설정 (firestore.rules, storage.rules)
   - main.dart에서 Firebase 초기화

2. **AuthService** (기본 인증):
   - 이메일/비밀번호 로그인
   - 현재 사용자 UID 조회
   - 로그아웃

**완료 기준**: Firebase Emulator에 연결 성공, 인증 플로우 동작

### Priority 2: 데이터 계층 (Data Layer)
**목표**: 타입 안전한 데이터 모델 및 서비스

1. **ReceiptRecord 모델**:
   - fromSnapshot 구현
   - toMap 구현
   - 단위 테스트 통과

2. **FirestoreService**:
   - createReceipt (필수 필드 검증 포함)
   - getReceipts (userId 필터링)
   - updateReceipt (isSubmitted 확인)
   - 단위 테스트 통과

3. **StorageService**:
   - uploadReceiptImage (크기/형식 검증)
   - getDownloadURL
   - 단위 테스트 통과

**완료 기준**: 모든 서비스 테스트 통과, Firebase Emulator에서 CRUD 동작 확인

### Priority 3: UI 계층 (Presentation Layer)
**목표**: shadcn_flutter 기반 사용자 인터페이스

1. **ReceiptUploadPage**:
   - 파일 선택 (file_picker)
   - 업로드 진행률 표시
   - 폼 입력 (날짜, 금액, 카테고리, 비즈니스 목적)
   - 제출 버튼 (필수 필드 검증)

2. **ReceiptListPage**:
   - StreamBuilder로 실시간 목록 표시
   - 영수증 카드 컴포넌트
   - 날짜/금액 포맷팅

3. **공통 위젯**:
   - ReceiptCard (shadcn_flutter Card 활용)
   - FilePickerButton (shadcn_flutter Button)
   - LoadingOverlay

**완료 기준**: 위젯 테스트 통과, 실제 UI 동작 확인

### Priority 4: 보안 및 검증 (Security & Validation)
**목표**: Firebase 보안 규칙 및 입력 검증

1. **Firestore 보안 규칙**:
   - 본인 영수증만 읽기/쓰기
   - 필수 필드 검증 (amount > 0, imageUrl 존재)
   - isSubmitted == false일 때만 수정 허용

2. **Storage 보안 규칙**:
   - 본인만 업로드/다운로드
   - 파일 크기 10MB 제한
   - MIME 타입 검증

3. **보안 규칙 테스트**:
   - @firebase/rules-unit-testing 사용
   - 권한 거부 시나리오 테스트

**완료 기준**: 보안 규칙 테스트 통과, 권한 위반 시 접근 거부 확인

---

## 4. Testing Strategy (테스트 전략)

### 4.1. 단위 테스트 (Unit Tests)
**도구**: Flutter Test + Mockito

- **모델 테스트**: ReceiptRecord fromSnapshot/toMap
- **서비스 테스트**: FirestoreService, StorageService (Firebase Emulator)
- **검증 로직 테스트**: Validator 클래스

**커버리지 목표**: 85% 이상

### 4.2. 위젯 테스트 (Widget Tests)
**도구**: Flutter Widget Testing

- **페이지 테스트**: ReceiptUploadPage, ReceiptListPage
- **컴포넌트 테스트**: ReceiptCard, FilePickerButton
- **상태 변화 테스트**: 로딩, 에러, 성공 상태

**커버리지 목표**: 주요 위젯 80% 이상

### 4.3. 통합 테스트 (Integration Tests)
**도구**: Firebase Emulator + Flutter Integration Test

- **End-to-End 플로우**:
  1. 로그인
  2. 영수증 업로드
  3. 목록 조회
  4. 로그아웃

**시나리오**: 최소 3개 (정상 플로우, 에러 플로우, 보안 플로우)

### 4.4. 보안 규칙 테스트
**도구**: @firebase/rules-unit-testing (Node.js)

- 인증되지 않은 접근 거부
- 다른 사용자 영수증 접근 거부
- 필수 필드 누락 시 생성 거부
- 제출된 영수증 수정 거부

**자동화**: `npm run test:rules` 스크립트

---

## 5. Risk Mitigation (리스크 대응)

### 기술적 리스크

| 리스크                       | 영향도 | 대응 방안                              |
|------------------------------|--------|----------------------------------------|
| Firebase Emulator 연결 실패  | High   | Emulator 설정 문서 참조, 포트 확인     |
| Flutter Web 파일 업로드 제약 | Medium | file_picker 라이브러리 사용, CORS 설정 |
| Firestore 보안 규칙 복잡도   | Medium | 단순화, 단위 테스트 강화               |
| shadcn_flutter 호환성 이슈   | Low    | 대체 UI 라이브러리 준비 (Material 3)   |

### 일정 리스크

| 리스크                  | 대응 방안                          |
|-------------------------|-----------------------------------|
| Firebase 설정 지연      | 1일차 우선 완료, 문서화            |
| 보안 규칙 테스트 복잡도 | 간단한 시나리오부터 점진적 확장     |
| UI 디자인 반복 작업     | Storybook 먼저 구축, 피드백 반영   |

---

## 6. Milestones (마일스톤)

### Milestone 1: 인프라 구축 ✅
**목표**: Firebase 연결 및 인증 완료

- Firebase Emulator 설정
- AuthService 구현
- 로그인 페이지 동작 확인

**검증**: Emulator UI에서 사용자 생성 확인

---

### Milestone 2: 데이터 계층 완성 ✅
**목표**: CRUD 기능 완료

- ReceiptRecord 모델
- FirestoreService 테스트 통과
- StorageService 테스트 통과

**검증**: `flutter test` 모두 통과

---

### Milestone 3: UI 구현 ✅
**목표**: 영수증 업로드 및 목록 페이지 완성

- ReceiptUploadPage 동작
- ReceiptListPage 실시간 동기화 확인
- shadcn_flutter 컴포넌트 통합

**검증**: 실제 브라우저에서 E2E 플로우 완료

---

### Milestone 4: 보안 강화 ✅
**목표**: 보안 규칙 테스트 통과

- Firestore/Storage 보안 규칙 작성
- 권한 테스트 통과
- 클라이언트 검증 추가

**검증**: `npm run test:rules` 통과

---

### Milestone 5: 문서화 및 배포 준비 ✅
**목표**: `/alfred:3-sync` 실행 준비

- Living Document 동기화
- README.md 업데이트
- deployment.md 작성 (Firebase Hosting)

**검증**: PR Ready 상태, CI/CD 통과

---

## 7. Definition of Done (완료 기준)

### 코드 품질
- [ ] 모든 단위 테스트 통과 (커버리지 ≥ 85%)
- [ ] 위젯 테스트 통과 (주요 컴포넌트 ≥ 80%)
- [ ] Firebase 보안 규칙 테스트 통과
- [ ] 린터 에러 0건 (`flutter analyze`)
- [ ] 포맷팅 준수 (`dart format`)

### SPEC 준수
- [ ] EARS 요구사항 모두 구현 확인
- [ ] TAG 체인 무결성 검증 (`rg '@(SPEC|TEST|CODE):RECEIPT-001'`)
- [ ] acceptance.md의 모든 시나리오 통과

### 문서화
- [ ] @CODE TAG 주석 추가
- [ ] TDD History 주석 작성
- [ ] API 문서 생성 (dart doc)

### Git 작업
- [ ] feature/SPEC-RECEIPT-001 브랜치 생성
- [ ] RED-GREEN-REFACTOR 단계별 커밋
- [ ] Draft PR 생성 (develop ← feature)

---

## 8. Next Steps (다음 단계)

1. **즉시 실행**: `/alfred:2-build SPEC-RECEIPT-001`
2. **TDD 구현**: RED → GREEN → REFACTOR 사이클 반복
3. **품질 검증**: TRUST 5원칙 준수 확인
4. **문서 동기화**: `/alfred:3-sync` 실행
5. **PR 머지**: 자동 또는 수동 머지 후 develop 체크아웃

---

**작성일**: 2025-10-14
**작성자**: @edward (spec-builder 에이전트)
**관련 SPEC**: SPEC-RECEIPT-001.md
