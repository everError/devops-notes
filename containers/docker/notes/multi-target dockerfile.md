# Multi-target Dockerfile — 단일 파일에서 여러 이미지 빌드

`FROM ... AS <name>` 으로 여러 stage 를 정의하고, **`docker build --target <name>`** 으로 원하는 stage 까지만 빌드해서 이미지를 만든다. 한 빌드 컨텍스트에서 여러 서비스 이미지를 효율적으로 만들 수 있다.

---

## 🎯 언제 쓰나

- **모노레포** — backend 여러 개, 또는 backend + frontend 가 같은 의존성 그래프 (예: 공유 라이브러리, 같은 SDK) 를 가짐
- **공통 빌드 단계** 가 있음 — restore/install 같은 큰 단계를 한 번만 수행하고 여러 산출물로 분기
- **runtime 이미지가 비슷** 함 — 같은 base, 같은 시스템 의존성

서비스마다 의존성/언어가 완전히 다르면 단일 Dockerfile 로 묶지 말고 **별도 Dockerfile** 이 더 명확하다.

---

## 1. 기본 구조

```dockerfile
# syntax=docker/dockerfile:1.7

# ─── 공통 build stage (한 번만 실행, 모든 서비스가 공유) ─────────
FROM node:22-alpine AS build
WORKDIR /src
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build:all                    # → /src/dist/{api,worker,web}

# ─── 공통 runtime base ──────────────────────────────────────
FROM node:22-alpine AS runtime-base
WORKDIR /app
RUN apk add --no-cache tini
USER node
ENTRYPOINT ["tini", "--"]

# ─── 서비스별 final stage ───────────────────────────────────
FROM runtime-base AS api
COPY --from=build /src/dist/api ./
CMD ["node", "server.js"]

FROM runtime-base AS worker
COPY --from=build /src/dist/worker ./
CMD ["node", "worker.js"]

FROM runtime-base AS web
COPY --from=build /src/dist/web ./
CMD ["node", "ssr.js"]
```

빌드:

```bash
docker build --target api    -t myapp/api    .
docker build --target worker -t myapp/worker .
docker build --target web    -t myapp/web    .
```

---

## 2. 핵심 — Build stage 캐시 공유

세 번 build 하면 매번 처음부터? **그렇지 않다.** Docker BuildKit 은 stage 단위 캐시를 자동 공유한다:

```
1번째 build: build stage 처음 실행 → npm ci, npm run build:all 모두 실행
2번째 build: build stage 가 캐시됨 → COPY --from=build 만 실행
3번째 build: 동일
```

따라서 세 이미지를 다 빌드해도 **공통 부분 (큰 npm install, 컴파일) 은 한 번만** 실행된다.

⚠️ **단, 같은 빌드 컨텍스트 + 같은 Dockerfile 일 때만.** matrix 병렬 빌드처럼 잡이 분리되면 캐시는 별도 메커니즘 (`--cache-from`) 으로 전달해야 한다.

---

## 3. CI 의 matrix 병렬 빌드와 결합

GitLab CI 에서 `parallel:matrix` 로 여러 잡 동시 실행:

```yaml
build:
  parallel:
    matrix:
      - SERVICE: api
      - SERVICE: worker
      - SERVICE: web
  script:
    - |
      docker build \
        --target "$SERVICE" \
        --cache-from "$REGISTRY/$SERVICE:cache" \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        -t "$REGISTRY/$SERVICE:$CI_COMMIT_SHORT_SHA" \
        -t "$REGISTRY/$SERVICE:latest" \
        -t "$REGISTRY/$SERVICE:cache" \
        .
    - docker push "$REGISTRY/$SERVICE:$CI_COMMIT_SHORT_SHA"
    - docker push "$REGISTRY/$SERVICE:latest"
    - docker push "$REGISTRY/$SERVICE:cache"
```

### 트레이드오프

| 방식 | 장점 | 단점 |
|---|---|---|
| 단일 잡에서 3개 다 빌드 | 캐시 공유 자동 | 직렬 → 느림 |
| matrix 병렬 + cache-from | 빠름 | 캐시는 registry 통해서만 공유 (network 비용) |

→ matrix 가 더 빠르지만, **첫 빌드 (cache 가 비어있을 때) 는 각 잡이 똑같은 build stage 를 따로따로 실행** 한다는 점 인지. 캐시가 워밍업되면 빨라짐.

---

## 4. Restore/Install 캐시 레이어 분리

흔한 실수: 소스 다 복사한 뒤 install:

```dockerfile
# ❌ 안티패턴
COPY . .
RUN npm ci
```

소스 한 줄만 바뀌어도 `COPY . .` 의 cache 가 무효화되어 `npm ci` 가 매번 다시 실행됨.

올바른 패턴 — manifest 만 먼저:

```dockerfile
# ✅ 캐시 친화적
COPY package.json package-lock.json ./
RUN npm ci                    # ← 이 레이어는 manifest 가 안 바뀌면 캐시 hit
COPY . .                      # 소스 변경은 여기 이후만 영향
RUN npm run build
```

같은 패턴이 .NET 에도 적용:

```dockerfile
COPY *.csproj ./
COPY services/api/api.csproj services/api/
COPY services/worker/worker.csproj services/worker/
RUN dotnet restore            # 캐시 hit
COPY . .
RUN dotnet publish --no-restore
```

---

## 5. 모노레포에서 csproj/package.json 만 먼저 복사

모노레포는 manifest 파일이 여러 개. 각각 명시적으로 COPY:

```dockerfile
COPY Directory.Packages.props NuGet.Config ./
COPY services/api/api.csproj         services/api/
COPY services/worker/worker.csproj   services/worker/
COPY shared/lib/lib.csproj           shared/lib/
RUN dotnet restore services/api/api.csproj \
 && dotnet restore services/worker/worker.csproj
COPY . .
RUN dotnet publish services/api/api.csproj         -c Release -o /app/publish/api
RUN dotnet publish services/worker/worker.csproj   -c Release -o /app/publish/worker
```

귀찮아 보이지만 한 번 만들어두면 manifest 변경 없는 한 restore 캐시 hit.

---

## 6. Final stage 만 차이 → DRY 한 base

런타임 stage 가 거의 동일하면 base 로 추출:

```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS runtime-base
WORKDIR /app
RUN apk add --no-cache icu-libs
ENV ASPNETCORE_URLS=http://*:8080
EXPOSE 8080
USER app

FROM runtime-base AS api
COPY --from=build /app/publish/api ./
ENTRYPOINT ["dotnet", "Api.dll"]

FROM runtime-base AS worker
COPY --from=build /app/publish/worker ./
ENTRYPOINT ["dotnet", "Worker.dll"]

FROM runtime-base AS web
COPY --from=build /app/publish/web ./
ENTRYPOINT ["dotnet", "Web.dll"]
```

각 final stage 가 3줄이면 충분.

---

## 7. 빌드 시 한 stage 만 빌드되는가?

`docker build --target api .` 하면 BuildKit 은 **`api` 가 의존하는 stage 만** 실행한다:

```
build → runtime-base → api    (실행됨)
build → runtime-base → worker (스킵)
build → runtime-base → web    (스킵)
```

따라서 matrix 잡에서 `--target api` 로 빌드하면 worker/web 의 final stage 는 만들어지지 않음.

⚠️ **단 build stage 는 공유되어 한 번만 실행됨** (매트릭스 잡이 cache 공유한다는 전제).

---

## 8. 흔한 함정

### 8.1 Final stage 에 `USER app` 설정인데 base 이미지에 `app` 사용자가 없음

`addgroup -S app && adduser -S app -G app` 추가 필요. 단 일부 base 이미지 (예: `mcr.microsoft.com/dotnet/aspnet:8+`) 는 이미 `app` 사용자가 만들어져 있으니 추가 시 `group 'app' in use` 에러.

→ base 이미지 문서 확인 후 결정.

### 8.2 `COPY --from=build` 의 경로

`build` stage 의 산출 경로를 정확히 매칭. publish output 디렉토리를 명시적으로 두는 게 안전:

```dockerfile
RUN dotnet publish ... -o /app/publish/api    # ← 명시
...
COPY --from=build /app/publish/api ./         # ← 같은 경로
```

### 8.3 Stage 이름과 Docker tag 충돌

```dockerfile
FROM nginx:alpine AS web
```

`docker build --target web` 했는데 base 이미지 의도였다면? 그땐 `--target` 못 씀. AS 이름은 stage 이름이고 tag 는 별개니 헷갈리지 말 것.

---

## 9. 디버깅 — 특정 stage 까지만 빌드

빌드 실패 원인 좁힐 때 유용:

```bash
docker build --target build -t debug:1 .       # build stage 까지만
docker run -it --rm debug:1 sh                 # 안에 들어가서 확인
```

또는 `--progress=plain` 으로 전체 로그 (잘림 없이) 확인:

```bash
DOCKER_BUILDKIT=1 docker build --progress=plain --no-cache --target api .
```

---

## ✅ 체크리스트

- [ ] 공통 build stage + 서비스별 final stage 구조
- [ ] manifest (csproj/package.json) 먼저 복사 → restore → COPY 나머지
- [ ] `--target` 으로 원하는 서비스만 빌드
- [ ] CI 에서 matrix 병렬 빌드 + `--cache-from registry/svc:cache`
- [ ] base 이미지의 기본 user / 폴더 / 의존성 확인 (예: `app` 사용자 충돌)
