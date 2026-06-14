# 덜어냄 Windows Installer Build

## 사전 요구 사항

1. **Flutter SDK** — `flutter build windows --release` 실행 가능 상태
2. **Inno Setup 6** — https://jrsoftware.org/isdl.php 에서 설치

## 빌드 순서

### 1. Flutter Release 빌드

```bash
cd apps/deoreonem_desktop
flutter build windows --release --dart-define=API_BASE_URL=https://deoreonem-api.scope-works.net/api/v1
```

빌드 결과물: `apps/deoreonem_desktop/build/windows/x64/runner/Release/`

### 2. 인스톨러 생성

Inno Setup Compiler (ISCC)를 사용합니다:

```bash
# 커맨드 라인 (Inno Setup이 PATH에 있는 경우)
iscc packaging/windows/deoreonem.iss

# 또는 전체 경로 사용
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" packaging/windows/deoreonem.iss
```

생성된 인스톨러: `dist/DeoReoNem-0.4-alpha-setup.exe`

### 3. 테스터 배포

- `dist/DeoReoNem-0.4-alpha-setup.exe`를 테스터에게 전달
- 또는 `apps/deoreonem_desktop/build/windows/x64/runner/Release/` 폴더를 ZIP으로 배포

## 참고

- 인스톨러는 사용자 권한(`PrivilegesRequired=lowest`)으로 설치됩니다
- 런타임 데이터는 `%APPDATA%\ScopeWorks\DeoReoNem`에 저장됩니다
- 제거 시 설치 폴더만 삭제됩니다 (AppData 런타임 데이터는 유지)
