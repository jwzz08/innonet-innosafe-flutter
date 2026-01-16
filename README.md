# innosafe
# Safety Monitor App

## 📌 프로젝트 개요
이 프로젝트는 건설 및 산업 현장의 안전을 실시간으로 모니터링하는 **Flutter 모바일 애플리케이션**입니다.

백엔드 API 서버와 연동하여 현장(Site), 작업자(Worker), 장비(Facility)의 상태를 관리하며, 향후 방송 및 카메라(Media) 연동 기능을 포함합니다.

---

## 아키텍처 및 기술 스택

### 1. Architecture: Feature-First Layered Architecture
기능(Feature) 단위로 폴더를 구분하여, 특정 기능과 관련된 UI, 상태 관리, 로직을 한곳에서 관리합니다.
* **Layer:** Presentation (UI) -> Application (State/Provider) -> Domain (Model) -> Data (Repository/API)

### 2. 주요 기술 스택 (Tech Stack)
* **Framework:** Flutter (Android 우선)
* **Language:** Dart
* **State Management:** `flutter_riverpod` (v2.x) - 전역 상태 및 의존성 주입
* **Navigation:** `go_router` - 딥링킹 및 중첩 네비게이션(ShellRoute) 지원
* **Networking:** `dio` - HTTP 클라이언트 (Interceptor를 통한 토큰 관리)
* **Storage:** `flutter_secure_storage` - JWT Access/Refresh 토큰 보안 저장
* **Code Generation:** `freezed`, `json_serializable` - 불변 객체 및 JSON 파싱 자동화

### 3. Site (현장 관리) 구조
기존 프로토타입 UI를 전면 개편하여, 웹 버전의 관제 기능을 모바일 환경에 최적화했습니다.

### 1. 탭 구조 재편 (Tab Restructuring)
* **Monitoring Tab (변경됨):**
    * 기존의 지도 뷰를 **리스트 뷰(List View)**로 변경하여, 구역별 수치 데이터를 빠르게 확인할 수 있습니다.
    * 상단에는 현장 전체 맵의 썸네일을 제공합니다.
* **Structure Tab (변경됨):**
    * 기존 리스트 뷰를 **인터랙티브 맵(Interactive Map)**으로 변경하여, 실제 도면 기반 관제 기능을 수행합니다.
    * 주요 기능: 도면 뷰어, 장비/작업자 위치 시각화, 카메라 연동.

### 2. Site Structure 기능 상세
* **Interactive Map Viewer:**
    * `InteractiveViewer`를 활용하여 고해상도 도면의 줌(Zoom) 및 팬(Pan)을 지원합니다.
    * 화면 높이(Height)를 기준으로 초기 스케일을 자동 계산하여 꽉 찬 화면을 제공합니다.
* **Smart HUD (Heads-Up Display):**
    * 지도 상단에 반투명 오버레이를 배치하여 총 작업자 수, 경고 장비, 센서 데이터 등 핵심 지표를 실시간 표시합니다.
* **Orientation Support (가로 모드 지원):**
    * **세로 모드:** 하단 정보창 및 네비게이션 바와 함께 표시.
    * **가로 모드:** 전체 화면(Full Screen)으로 전환되며, 불필요한 UI(AppBar, FAB 등)는 자동으로 숨김 처리됩니다.
    * **Side Panel (Inspector):** 가로 모드에서 아이콘 클릭 시, 화면을 가리지 않도록 우측에서 슬라이드 패널이 등장하여 상세 정보를 표시합니다.
* **Camera Integration:**
    * 장비 아이콘 클릭 시 해당 장비의 카메라 뷰(`CameraViewScreen`)로 즉시 이동합니다.

### 3. API 연동 (Data Layer)
* **Repository Pattern:** `SiteRepository`를 통해 API와 통신하며, `SiteStructureModel`로 데이터를 매핑합니다.
* **Riverpod Provider:** `siteStructureProvider`를 통해 UI에 비동기 데이터(`AsyncValue`)를 공급합니다.
---

## 프로젝트 폴더 구조 (Directory Structure)

```text
lib/
├── main.dart                     # 앱 진입점 (ProviderScope 설정)
├── app.dart                      # MaterialApp, Router, Theme 설정
│
├── core/                         # 앱 전반에서 사용되는 공통 모듈
│   ├── constants/                # API Endpoints (/api/v1 등)[cite: 5], UI 상수
│   ├── theme/                    # AppTheme (다크 모드, 컬러 팔레트)
│   ├── router/                   # GoRouter 설정 (Auth기반 리다이렉트 포함)
│   ├── network/                  # Dio Client (Header, Interceptor 설정)
│   └── storage/                  # Local Storage Wrapper
│
├── features/                     # 기능별 모듈 (Feature-First)
│   ├── auth/                     # [기능 1] 로그인 및 인증
│   │   ├── data/                 # AuthRepository, DTO
│   │   ├── provider/             # AuthController (Riverpod)
│   │   └── presentation/         # LoginScreen
│   │
│   ├── home/                     # [기능 2] 홈 (대시보드)
│   │   └── presentation/         # HomeScreen (종합 안전 점수, 알림 요약)
│   │
│   ├── site/                     # [기능 3] 현장 관리 (Map, Structure)
│   │   └── presentation/         # SiteScreen (현장 맵, 구역 모니터링)
│   │
│   ├── facility/                 # [기능 4] 시설/장비 관리
│   │   └── presentation/         # FacilityScreen (장비 리스트, 센서 상태)
│   │
│   ├── media/                    # [기능 5] 방송 및 미디어 (확장 예정)
│   │   └── presentation/         # MediaScreen (RTSP 플레이어, 방송 제어)
│   │
│   └── settings/                 # [기능 6] 설정
│       └── presentation/         # SettingsScreen (로그아웃, 내 정보, 회사 관리 이동)
│
└── shared/                       # 공용 위젯 및 유틸리티
    ├── widgets/                  # MetricCard, CustomTextField 등 재사용 위젯
    └── models/                   # 공용 모델 (User, Error 등)
