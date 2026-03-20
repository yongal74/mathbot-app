# App Store Connect + Google Play Console 설정 가이드

**Bundle ID (iOS)**: `com.mathbot.csat_tree`
**Package Name (Android)**: `com.mathbot.csat_tree`

---

## 1. App Store Connect (iOS)

### 1-1. 앱 등록
1. https://appstoreconnect.apple.com 접속
2. **나의 앱** > **+** > **신규 앱**
3. 플랫폼: iOS, 이름: `수능수학 조건분해트리`, 번들 ID: `com.mathbot.csat_tree`

### 1-2. 인앱 구독 상품 등록
**앱 > 수익화 > 구독** 으로 이동

**구독 그룹 생성** → 이름: `수능수학 조건분해트리 구독`

**PRO 구독 추가**:
- 제품 ID: `mathbot_pro_monthly`
- 참조 이름: `PRO 월간`
- 가격: 한국 ₩9,900 (Tier 8)
- 구독 기간: 1개월
- 한국어 설명: "개념 설명, TTS 음성, 오답노트 무제한, 사진 분석 20회/월"

**PREMIUM 구독 추가**:
- 제품 ID: `mathbot_premium_monthly`
- 참조 이름: `PREMIUM 월간`
- 가격: 한국 ₩15,900 (Tier 13)
- 구독 기간: 1개월
- 한국어 설명: "PRO 전체 기능 + 사진 분석 100회/월"

### 1-3. 공유 암호 (Shared Secret) 발급 → 서버 설정에 필요
**앱 > 수익화 > 구독 > 앱별 공유 암호** > **생성**
→ 이 값을 서버 `.env`의 `APPLE_SHARED_SECRET`에 입력

---

## 2. Google Play Console (Android)

### 2-1. 앱 등록
1. https://play.google.com/console 접속
2. **앱 만들기** > 앱 이름: `수능수학 조건분해트리`, 패키지: `com.mathbot.csat_tree`

### 2-2. 구독 상품 등록
**수익 창출 > 구독** > **구독 만들기**

**PRO 구독**:
- 제품 ID: `mathbot_pro_monthly`
- 이름: `PRO 월간 구독`
- 청구 주기: 월간 (1개월)
- 가격: 한국 ₩9,900

**PREMIUM 구독**:
- 제품 ID: `mathbot_premium_monthly`
- 이름: `PREMIUM 월간 구독`
- 청구 주기: 월간 (1개월)
- 가격: 한국 ₩15,900

### 2-3. 서비스 계정 생성 → 서버 사이드 영수증 검증에 필요
1. **설정 > API 액세스** > **새 서비스 계정 만들기**
2. Google Cloud Console로 이동 → 서비스 계정 생성
3. 역할: **서비스 계정 토큰 생성자** + **편집자**
4. **JSON 키 다운로드**
5. Google Play Console로 돌아와 해당 서비스 계정에 **재무 데이터 보기** 권한 부여
6. JSON 파일 내용을 한 줄로 변환 → 서버 `.env`의 `GOOGLE_SERVICE_ACCOUNT_JSON`에 입력

---

## 3. Firebase 설정 및 배포

### 3-1. Firebase 프로젝트 생성
1. https://console.firebase.google.com 접속
2. **프로젝트 추가** > 이름: `mathbot-csat-tree`
3. **Blaze 요금제 업그레이드** (외부 API 호출을 위해 필수 — 사용량 적으면 사실상 무료)

### 3-2. Firebase CLI 설치 및 로그인
```bash
npm install -g firebase-tools
firebase login
firebase use mathbot-csat-tree
```

### 3-3. 환경 변수 설정
```bash
# Apple Shared Secret (App Store Connect에서 발급)
firebase functions:config:set apple.shared_secret="YOUR_APPLE_SHARED_SECRET"

# Google Service Account JSON (한 줄로 만들어서 입력)
firebase functions:config:set google.service_account='{"type":"service_account",...}'

# API 보안 키 (임의의 긴 문자열)
firebase functions:config:set app.api_key="YOUR_RANDOM_SECRET_KEY"

# Android 패키지 이름
firebase functions:config:set app.package_name="com.mathbot.csat_tree"
```

### 3-4. 배포
```bash
cd functions && npm install && cd ..
firebase deploy --only functions,hosting
```

배포 완료 후 생성되는 Functions URL을 Flutter 빌드 시 주입:
```bash
# Functions URL 확인
firebase functions:list

# Flutter 빌드 (iOS)
flutter build ios \
  --dart-define=VERIFY_SERVER_URL=https://asia-northeast3-mathbot-csat-tree.cloudfunctions.net \
  --dart-define=VERIFY_API_KEY=YOUR_RANDOM_SECRET_KEY

# Flutter 빌드 (Android)
flutter build appbundle \
  --dart-define=VERIFY_SERVER_URL=https://asia-northeast3-mathbot-csat-tree.cloudfunctions.net \
  --dart-define=VERIFY_API_KEY=YOUR_RANDOM_SECRET_KEY
```

---

## 4. 개인정보처리방침 URL 등록

Firebase Hosting 배포 후 아래 URL을 각 스토어에 입력:
- 개인정보처리방침: `https://mathbot-csat-tree.web.app/privacy`
- 이용약관: `https://mathbot-csat-tree.web.app/terms`

또는 GitHub Pages URL (이미 배포됨):
- 개인정보처리방침: `https://yongal74.github.io/mathbot-app/privacy`
- 이용약관: `https://yongal74.github.io/mathbot-app/terms`

---

## 5. Xcode Bundle ID 변경

```
Xcode > Runner > Signing & Capabilities > Bundle Identifier:
com.mathbot.csat_tree
```

Team: Apple Developer 계정 선택 후 자동 서명
