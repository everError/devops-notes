# 🛠️ .NET 빌드 명령어 정리

.NET 프로젝트를 개발하고 배포할 때 사용되는 주요 `dotnet` 명령어들을 정리합니다.

---

## 📌 1️⃣ NuGet 패키지 복원 (`dotnet restore`)

```bash
dotnet restore
```

✔ 프로젝트(`.csproj` 또는 `.sln`)에 정의된 NuGet 패키지를 복원합니다.  
✔ 네트워크 연결이 필요한 경우 원격 저장소(NuGet.org 등)에서 패키지를 가져옵니다.  
✔ **CI/CD 또는 Docker 빌드 시** 빌드 전에 실행하는 것이 일반적입니다.

### 특정 `NuGet.config` 사용하여 복원

```bash
dotnet restore --configfile Nuget.config
```

✔ 지정한 NuGet 설정 파일(`Nuget.config`)을 사용하여 패키지를 복원합니다.

### 캐시된 패키지 제거 후 복원

```bash
dotnet nuget locals all --clear
```

✔ 로컬 캐시를 지운 후 새롭게 패키지를 다운로드하여 복원합니다.

---

## 📌 2️⃣ 프로젝트 빌드 (`dotnet build`)

```bash
dotnet build
```

✔ 프로젝트를 **컴파일**하고 **출력 폴더(`bin/Debug/net6.0/` 등)에 빌드 아티팩트 생성**
✔ `.dll` 파일이 생성되며, `dotnet run`으로 실행 가능
✔ **자동으로 `dotnet restore` 실행됨** (별도로 실행할 필요 없음)

### `Release` 모드로 빌드

```bash
dotnet build -c Release
```

✔ 최적화된 `Release` 모드로 빌드하여 배포에 적합한 바이너리 생성

### `restore` 제외하고 빌드 (`restore`가 이미 수행된 경우)

```bash
dotnet build --no-restore
```

✔ 패키지 복원을 건너뛰고 빌드만 수행하여 속도를 개선

---

## 📌 3️⃣ 실행 (`dotnet run`)

```bash
dotnet run
```

✔ 현재 디렉토리의 `.NET` 프로젝트를 빌드 후 실행합니다.
✔ **자동으로 `dotnet build` 실행됨**

### 특정 `Release` 빌드 실행

```bash
dotnet run --configuration Release
```

✔ `Release` 모드로 빌드된 파일을 실행

---

## 📌 4️⃣ 배포용 패키지 생성 (`dotnet publish`)

```bash
dotnet publish -c Release -o ./publish
```

✔ `Release` 모드로 빌드 후 배포 가능한 파일을 `./publish` 폴더에 생성
✔ **웹 애플리케이션, API 서비스 배포 시 필수**
✔ `dotnet AuthService.dll`처럼 실행 가능

---

## 🎯 결론

- **`dotnet restore`** → NuGet 패키지를 복원
- **`dotnet build`** → 프로젝트 빌드 (`restore` 포함됨)
- **`dotnet run`** → 개발 모드에서 프로젝트 실행
- **`dotnet publish`** → 배포를 위한 최종 패키지 생성
