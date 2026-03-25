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

---

## 3. Site (현장 관리) 구조

### 3.1 탭 구조 재편 (Tab Restructuring)
* **Monitoring Tab (변경됨):**
    * 기존의 지도 뷰를 **리스트 뷰(List View)**로 변경하여, 구역별 수치 데이터를 빠르게 확인할 수 있습니다.
    * 상단에는 현장 전체 맵의 썸네일을 제공합니다.
* **Structure Tab (변경됨 - 2025.01 전면 개편):**
    * 기존 리스트 뷰를 **인터랙티브 맵(Interactive Map)**으로 변경하여, 실제 도면 기반 관제 기능을 수행합니다.
    * 주요 기능: 도면 뷰어, 장비/작업자 위치 시각화, 카메라 연동.

---

### 3.2 Site Structure 기능 상세 (2025.01 전면 개편)

#### 아키텍처 변경 사항 (Architecture Refactoring)

**기존 방식 (2024.12 이전):**
```
Position API 직접 호출
  ↓
하드코딩된 좌표 계산
  ↓
UI 렌더링 (Layout 정보 무시)
```

**개편 방식 (2025.01):**
```
1. Layout Load:
   Dashboard API (/api/v1/dashboards/{id})
   ↓
   Widget 구조 파싱 (iconList, tableList)
   ↓
   Icon Type별 Factory 패턴 렌더링

2. Real-time Overlay:
   Position API (/api/v1/sitegroups/{id}/position/entrants)
   ↓
   humanCount 실시간 업데이트 (30초 주기)
   ↓
   UI 반영 (기존 Layout 유지)
```

**주요 개선점:**
- ✅ **Dashboard 시스템 전면 도입** - 백엔드 Layout 구조 완전 준수
- ✅ **Icon Type 7종 지원** - BLE, BleSum, TotalSum, ExcavationRate, EquipmentSum, MaterialSum, TVWS
- ✅ **Factory Pattern** - 확장 가능한 Icon 렌더링 시스템
- ✅ **Layout/Position 분리** - 정적 레이아웃과 동적 데이터 독립 관리
- ✅ **Provider 계층화** - Dashboard, Position, Enriched Structure 3단 구조

---

#### 주요 기능 (Features)

**1. Interactive Map Viewer**
* `InteractiveViewer`를 활용하여 고해상도 도면의 줌(Zoom) 및 팬(Pan)을 지원합니다.
* 화면 높이(Height)를 기준으로 초기 스케일을 자동 계산하여 꽉 찬 화면을 제공합니다.
* **도면 좌표 시스템:** `xPercent`, `yPercent` (0-100%) → Pixel 자동 변환

**2. Smart HUD (Heads-Up Display)**
* 지도 상단에 반투명 오버레이를 배치하여 총 작업자 수, 경고 장비, 센서 데이터 등 핵심 지표를 실시간 표시합니다.
* **실시간 업데이트:** 30초마다 Position API 자동 갱신 (StreamProvider)

**3. Icon Type 지원 (7종)**
| Type | 설명 | 용도 |
|------|------|------|
| **BLE** | 단일 디바이스 | 개별 작업자 위치 표시 |
| **BleSum** | 복수 디바이스 집계 | 그룹 작업자 강조 표시 |
| **TotalSum** | 전체 인원수 Badge | 현장 총 인원 한눈에 확인 |
| **EquipmentSum** | 장비 개수 Badge | 투입 장비 수량 표시 |
| **MaterialSum** | 자재 개수 Badge | 사용 자재 수량 표시 |
| **ExcavationRate** | 굴진율 Progress Bar | 공사 진행률 시각화 |
| **TVWS (Master/Slave)** | 통신 장비 | 네트워크 인프라 표시 |

**4. Orientation Support (가로 모드 지원)**
* **세로 모드:** 하단 정보창 및 네비게이션 바와 함께 표시.
* **가로 모드:** 전체 화면(Full Screen)으로 전환되며, 불필요한 UI(AppBar, FAB 등)는 자동으로 숨김 처리됩니다.
* **Side Panel (Inspector):** 가로 모드에서 아이콘 클릭 시, 화면을 가리지 않도록 우측에서 슬라이드 패널이 등장하여 상세 정보를 표시합니다. (구현 예정)

**5. Camera Integration** (구현 예정)
* 장비 아이콘 클릭 시 해당 장비의 카메라 뷰(`CameraViewScreen`)로 즉시 이동합니다.

---

#### 데이터 흐름 (Data Flow)

```
┌─────────────────────────────────────────────────────────────┐
│ UI Layer (SiteStructureSideTab)                             │
│  - InteractiveViewer (Pan/Zoom)                             │
│  - MapIconFactory (Type별 Widget 생성)                      │
│  - HUD, FAB Buttons                                         │
└─────────────────────────────────────────────────────────────┘
                          ↓ ref.watch()
┌─────────────────────────────────────────────────────────────┐
│ Provider Layer                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ dashboardListProvider                                  │ │
│  │  → GET /api/v1/sitegroups/{id}/dashboards             │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ enrichedStructureProvider (결합)                      │ │
│  │  ├─ dashboardDetailProvider                           │ │
│  │  │   → GET /api/v1/dashboards/{id}                    │ │
│  │  │   → iconList, tableList 파싱                       │ │
│  │  └─ positionAggregationProvider                       │ │
│  │      → GET /api/v1/sitegroups/{id}/position/entrants  │ │
│  │      → humanCount 집계                                 │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ Repository Layer                                            │
│  - DashboardRepository (Layout 전용)                        │
│  - PositionRepository (실시간 데이터)                       │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ API Server (Backend)                                        │
│  - Dashboard/Widget 구조 관리                               │
│  - 실시간 Position 데이터 제공                              │
└─────────────────────────────────────────────────────────────┘
```

---

#### 파일 구조 (File Structure)

```
lib/features/site/
├── data/
│   ├── model/
│   │   ├── dashboard_models.dart       # Dashboard, Widget, Icon 모델
│   │   ├── position_models.dart        # 실시간 위치 데이터 모델
│   │   └── site_group_model.dart       # Site 목록 모델
│   └── repository/
│       ├── dashboard_repository.dart   # Layout API
│       ├── position_repository.dart    # Position API
│       └── site_repository.dart        # Site 목록 API
├── provider/
│   └── site_structure_providers.dart   # 통합 Provider (현재는 Tab 내부)
└── presentation/
    ├── tabs/
    │   └── site_structure_sidetab.dart # 메인 Structure Tab
    └── widgets/
        ├── map_icon_factory.dart       # Icon Factory Pattern
        ├── icon_types.dart             # 7개 Icon Widget 통합
        ├── worker_info_sheet.dart      # Bottom Sheet (작업자 상세)
        └── camera_view_screen.dart     # 카메라 뷰 (미구현)
```

---

#### 향후 작업 (TODO)

**High Priority:**
- [ ] 실제 API 연동 (Mock → Real API)
- [ ] Widget Drawing API 연동 (도면 이미지 동적 로드)
- [ ] TableList UI 구현 (디바이스 상세 정보)
- [ ] Side Panel (가로 모드 작업자 상세)

**Medium Priority:**
- [ ] WebSocket 실시간 업데이트 (Polling → WebSocket)
- [ ] 카메라 RTSP 스트리밍 연동
- [ ] Alarm API 연동 (HUD 경고 수 표시)
- [ ] Sensor API 연동 (HUD 센서/온도 표시)

**Low Priority:**
- [ ] 성능 최적화 (Icon Visibility Culling)
- [ ] 다크 모드 테마 적용
- [ ] 오프라인 캐싱 (Hive 등)

---

## 프로젝트 폴더 구조 (Directory Structure)

```text
lib/
├── main.dart                     # 앱 진입점 (ProviderScope 설정)
├── app.dart                      # MaterialApp, Router, Theme 설정
│
├── core/                         # 앱 전반에서 사용되는 공통 모듈
│   ├── constants/                # API Endpoints, UI 상수
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
│   │   ├── data/
│   │   │   ├── model/
│   │   │   │   ├── dashboard_models.dart
│   │   │   │   ├── position_models.dart
│   │   │   │   └── site_group_model.dart
│   │   │   └── repository/
│   │   │       ├── dashboard_repository.dart
│   │   │       ├── position_repository.dart
│   │   │       └── site_repository.dart
│   │   ├── provider/
│   │   │   └── site_structure_providers.dart
│   │   └── presentation/
│   │       ├── tabs/
│   │       │   ├── site_overview_tab.dart
│   │       │   ├── site_monitoring_tab.dart
│   │       │   └── site_structure_sidetab.dart (★ 전면 개편)
│   │       └── widgets/
│   │           ├── map_icon_factory.dart
│   │           ├── icon_types.dart
│   │           ├── worker_info_sheet.dart
│   │           └── camera_view_screen.dart
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
```

---

## 📝 Changelog

### [2025.01.17] - Site Structure Tab 전면 개편
**Added:**
- Dashboard API 기반 Layout 시스템 도입
- Icon Factory Pattern (7종 Icon Type 지원)
- 실시간 Position 데이터 오버레이
- Provider 계층 분리 (Dashboard/Position/Enriched)
- Mock Provider 테스트 환경 구축

**Changed:**
- 기존 Position API 직접 호출 방식 → Dashboard 기반 Layout 로드
- 하드코딩 좌표 → Percent 기반 동적 계산
- 단순 원형 아이콘 → Type별 전문 Widget

**Technical Debt:**
- Provider 파일 분리 필요 (현재 Tab 내부)
- 실제 API 연동 대기 (Mock 데이터 사용 중)
- TableList, Side Panel 미구현

---

## 🚀 Getting Started

### Prerequisites
```bash
flutter --version  # Flutter 3.x 이상
dart --version     # Dart 3.x 이상
```

### Installation
```bash
git clone <repository-url>
cd innosafe
flutter pub get
flutter run
```

### Environment Variables
```dart
// lib/core/constants/api_constants.dart
static const String baseUrl = 'http://220.76.77.250:5003/api/v1';
```

---

## 📄 License
This project is proprietary and confidential.