# Windows Service 배포 가이드 (일반적인 .NET 프로그램 배포)

이 문서는 Windows 환경에서 .NET 기반 콘솔 애플리케이션을 Windows Service 로 배포하고 운영하는 방법을 정리한 가이드입니다. 특정 프로젝트가 아닌, 일반적인 환경을 기준으로 작성되었습니다.

## 📦 1. 프로젝트 Publish (배포 파일 생성)

프로젝트를 Windows Server 에 배포하려면 먼저 배포 가능한 파일을 생성해야 합니다.

### 터미널 또는 PowerShell 에서 실행:

```bash
dotnet publish -c Release -r win-x64 --self-contained true /p:PublishSingleFile=true
```

- `-c Release`: Release 모드 빌드
- `-r win-x64`: Windows 64비트 플랫폼 대상으로 빌드
- `--self-contained true`: .NET 런타임 포함 (서버에 .NET 설치 불필요)
- `/p:PublishSingleFile=true`: 단일 실행 파일로 패키징

> 📂 결과:
> `bin/Release/net6.0/win-x64/publish/` 폴더가 생성됩니다.

## 🚀 2. 배포 파일 서버로 복사

생성된 `publish` 폴더 전체를 Windows 서버의 원하는 경로로 복사합니다.

예시:
```
C:\Services\MyApplication\
```

> **중요:** 환경설정 파일(`appsettings.json` 등)도 함께 복사해야 합니다.

## ✅ 3. Windows Service 로 등록

Windows Service 는 Windows 운영체제의 서비스 관리자에서 관리되며, 자동 시작 및 수동 시작이 가능합니다.

### PowerShell 이용:

```powershell
New-Service -Name "ServiceName" -BinaryPathName "C:\Services\MyApplication\App.exe" -DisplayName "My Windows Service" -Description "Service Description"
```

### CMD (sc.exe 명령)

```cmd
sc create ServiceName binPath= "C:\Services\MyApplication\App.exe"
```

> **참고:**
> - `ServiceName`: 서비스 이름 (cmd 또는 PowerShell 에서 사용)
> - `App.exe`: 실행 파일 이름

## ⏳ 4. 서비스 시작

서비스가 등록되면 수동으로 시작하거나 서버가 재부팅될 때 자동으로 시작하도록 설정할 수 있습니다.

### PowerShell 이용:
```powershell
Start-Service -Name "ServiceName"
```

### CMD 이용:
```cmd
net start ServiceName
```

## 🚀 5. 자동 시작 및 재시작 설정

### 서비스 자동 시작:
```powershell
Set-Service -Name "ServiceName" -StartupType Automatic
```

### 서비스 실패 시 자동 재시작:
```cmd
sc failure ServiceName reset= 0 actions= restart/5000
```
- 서비스 실패 시 5초 후 자동 재시작
- `reset= 0`: 실패 횟수 초기화 안 함 (영구 재시도)

## 🔍 6. 서비스 로그 확인

서비스 동작 상태 및 오류 발생 시, 이벤트 로그를 확인하여 문제를 파악합니다.

- **Windows Event Viewer**
  - Windows Logs > Application > 해당 프로그램 이름을 통해 확인
- 프로그램 내에서 `ILogger` 또는 `EventLog` 를 사용하여 로그 기록을 권장합니다.

---

## 🌟 전체 요약

| 단계 | 작업 내용 |
|---|---|
| ✅ 1 | `dotnet publish` 로 배포 파일 생성 |
| ✅ 2 | 배포 파일을 서버에 복사 |
| ✅ 3 | PowerShell 또는 CMD 를 통해 서비스 등록 |
| ✅ 4 | 서비스 시작 및 동작 확인 |
| ✅ 5 | 자동 시작 및 재시작 설정 |
| ✅ 6 | 이벤트 로그 확인 |

---

## 💡 참고: 고급 운영 가이드

추가적으로 자동화 및 복구 관리를 위해 아래 사항을 고려할 수 있습니다.

- PowerShell 자동 배포 스크립트 활용
- 서비스 갱신 및 재배포 시 이벤트 로그 확인 및 관리
- 환경별 `appsettings.json` 설정 분리 및 관리
- CI/CD 파이프라인을 통한 자동 배포