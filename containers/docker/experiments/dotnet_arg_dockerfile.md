### 1️⃣ ARG 정의 (FROM 이전)

```dockerfile
ARG PROJECT_DIR
ARG PROJECT_NAME
```

- 빌드 시 사용할 프로젝트 폴더명과 `.csproj` 파일명을 외부에서 받기 위한 인자입니다.

---

### 2️⃣ Build Stage 정의

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG PROJECT_DIR
ARG PROJECT_NAME
```

- SDK 이미지를 기반으로 빌드 단계 구성.
- FROM 이후에도 ARG를 다시 선언해야 해당 스테이지 내에서 사용 가능합니다.

```dockerfile
WORKDIR /app
COPY . .
```

- 전체 컨텍스트 내용을 `/app` 경로에 복사.

```dockerfile
WORKDIR /app/${PROJECT_DIR}
RUN dotnet restore ${PROJECT_NAME}.csproj
```

- 해당 프로젝트 디렉토리로 이동한 후 `dotnet restore` 수행.

```dockerfile
RUN dotnet publish ${PROJECT_NAME}.csproj -c Release -o /app/publish --no-restore
```

- 릴리즈 모드로 `dotnet publish`, 결과물은 `/app/publish` 디렉토리에 생성.

---

### 3️⃣ Runtime Stage 정의

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
ARG PROJECT_NAME
ENV PROJECT_NAME=${PROJECT_NAME}
```

- 런타임 이미지는 더 가볍고 실행만 담당합니다.
- ENTRYPOINT에서 환경변수를 사용하려면 ENV로 설정이 필요.

```dockerfile
WORKDIR /app
COPY --from=build /app/publish ./
```

- 빌드 스테이지의 publish 결과를 현재 이미지로 복사.

```dockerfile
ENTRYPOINT ["/bin/sh", "-c", "dotnet \"$PROJECT_NAME.dll\""]
```

- 런타임에서 `ENV`로 지정한 `PROJECT_NAME`을 기반으로 동적으로 `.dll` 실행.
- ENTRYPOINT를 `/bin/sh -c` 형태로 사용함으로써 ENV 변수가 런타임에 치환될 수 있도록 함.

---

## ✅ 사용 예시 (Jenkins 또는 터미널에서)

```bash
docker build   --build-arg PROJECT_DIR=mes-testing   --build-arg PROJECT_NAME=mes-testing   -t myrepo/mes-testing:latest   -f ./Dockerfile .
```
