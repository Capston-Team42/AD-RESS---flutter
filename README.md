# Flutter 클라이언트 - AD*RESS
이 저장소는 `AD*RESS`의 Flutter 기반 모바일 애플리케이션 소스코드입니다.<br>`AD*RESS`는 백엔드 API와 연동하여 사용자 일정, 옷장 데이터, 추천 결과 등을 처리하는 클라이언트 앱입니다.

---

## 실행 방법 (GitHub에서 클론 후 실행 가능)

Flutter가 설치된 환경에서 다음과 같이 실행할 수 있습니다.

---

### 1. 레포지토리 클론

```bash
git clone https://github.com/Capston-Team42/AD-RESS---flutter.git
cd AD-RESS---flutter
```
### 2. 의존성 설치

```bash
flutter pub get
```

### 3. 환경 변수 설정

프로젝트 루트 디렉토리에 `.env` 파일이 필요합니다.
다음 명령어로 예시 파일을 복사하여 시작하세요:
```bash
make env
```
`.env.example` 파일은 다음과 같은 형식입니다. 실제 API 키로 값을 대체해주세요:

```ini
# 예시 .env 파일 (your_api_key를 실제 키로 교체하세요)
OPENAI_API_KEY=your_api_key
OPENWEATHER_API_KEY=your_api_key
GOOGLE_MAPS_API_KEY=your_api_key
BACKEND_IP_REC=13.125.178.76
BACKEND_IP_WAR=15.164.94.237
```

### 4. 앱 실행 (디버그 모드, 실제 Android 기기 연결)

1. Android 기기를 USB로 연결
2. 디바이스가 인식되었는지 확인한 후, 아래 명령어 실행
```bash
flutter run
``` 
### 5. APK 빌드 방법(직접 배포)

Flutter가 설치된 환경에서 다음 명령어를 통해 직접 `.apk` 파일을 빌드할 수 있습니다:
```bash
flutter build apk --release
```
빌드된 APK는 build/app/outputs/flutter-apk/app-release.apk 경로에 생성됩니다.


### + Makefile로 빠르게 실행하기
#### Makefile 명령 요약
```bash
make env     # .env 설정
make run     # 앱 실행
make build   # 릴리즈 APK 빌드
make clean   # 캐시/빌드 정리
```

#### Makefile 내용
```makefile
clean:
	flutter clean

run:
	flutter pub get
	flutter run

build:
	flutter pub get
	flutter build apk --release

env:
	cp .env.example .env
```
---
## 오픈소스 라이브러리 사용 목록

본 프로젝트는 다음 오픈소스 라이브러리를 사용하고 있습니다:

| 라이브러리 | 설명 | 링크 |
|------------|------|------|
| `provider` | 상태 관리 | [provider](https://pub.dev/packages/provider) |
| `http` | HTTP 통신 | [http](https://pub.dev/packages/http) |
| `flutter_dotenv` | 환경 변수 관리 | [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) |
| `geolocator` | 위치 정보 가져오기 | [geolocator](https://pub.dev/packages/geolocator) |
| `geocoding` | 위경도 → 주소 변환 | [geocoding](https://pub.dev/packages/geocoding) |
| `permission_handler` | 권한 요청 처리 | [permission_handler](https://pub.dev/packages/permission_handler) |
| `device_calendar` | 디바이스 캘린더 접근 | [device_calendar](https://pub.dev/packages/device_calendar) |
| `url_launcher` | 외부 URL 열기 | [url_launcher](https://pub.dev/packages/url_launcher) |
| `shared_preferences` | 로컬 저장소 | [shared_preferences](https://pub.dev/packages/shared_preferences) |
| `google_maps_flutter` | 구글 지도 연동 | [google_maps_flutter](https://pub.dev/packages/google_maps_flutter) |
| `flutter_google_places_sdk` | 구글 장소 검색 | [flutter_google_places_sdk](https://pub.dev/packages/flutter_google_places_sdk) |
| `marquee` | 텍스트 흐름 애니메이션 | [marquee](https://pub.dev/packages/marquee) |
| `image_picker` | 이미지 선택 | [image_picker](https://pub.dev/packages/image_picker) |
| `image_cropper` | 이미지 자르기 | [image_cropper](https://pub.dev/packages/image_cropper) |
| `flutter_secure_storage` | 보안 저장소 | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) |
| `flutter_image_compress` | 이미지 압축 | [flutter_image_compress](https://pub.dev/packages/flutter_image_compress) |
| `intl` | 날짜/시간 포맷 | [intl](https://pub.dev/packages/intl) |
| `flutter_launcher_icons` | 런처 아이콘 설정 | [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) |
| `flutter_native_splash` | 스플래시 화면 설정 | [flutter_native_splash](https://pub.dev/packages/flutter_native_splash) |
| `overlay_support` | 토스트/오버레이 UI | [overlay_support](https://pub.dev/packages/overlay_support) |

---

## 외부 API 사용

본 프로젝트는 다음 외부 API를 사용하여 주요 기능을 구현하고 있습니다:

| API 이름 | 사용 목적 | 링크 |
|----------|-----------|------|
| OpenAI API | 사용자 입력 기반 코디 추천 및 자연어 분석 | [OpenAI API Docs](https://platform.openai.com/docs) |
| OpenWeatherMap API | 사용자의 위치 기반 날씨 정보 수집 | [OpenWeatherMap API](https://openweathermap.org/api) |
| Google Maps API | 지도 위치 검색 및 좌표 변환 | [Google Maps API](https://developers.google.com/maps/documentation) |
| Google Places API | 장소 자동완성 및 추천 | [Places API](https://developers.google.com/maps/documentation/places/web-service/overview) |
