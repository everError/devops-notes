# BuildKit Secrets — Docker 빌드 시 비밀값 안전 주입

`docker build` 도중에만 임시로 secret 을 마운트해서 사용. 이미지 레이어에 박히지 않고, 빌드 캐시에도 평문으로 남지 않음.

---

## 🔥 왜 ARG 로 받으면 안 되나

흔한 안티패턴:

```dockerfile
ARG GITHUB_TOKEN
RUN git clone "https://x-access-token:${GITHUB_TOKEN}@github.com/myorg/private.git"
```

```bash
docker build --build-arg GITHUB_TOKEN=ghp_xxxxxxxxxx -t myimage .
```

문제:

1. **이미지 레이어에 박힘** — `docker history myimage` 에 `--build-arg GITHUB_TOKEN=...` 그대로 노출.
2. **registry 로 push 되면 누구나 봄** — 외부 레지스트리에 올리면 접근권한 가진 모두에게 토큰 유출.
3. **빌드 캐시도 평문 보존** — 다른 빌드의 캐시에 남을 수 있음.

CI 변수로 Masked 처리 해도 **빌드 결과물에 박히는 건 별개 문제**.

---

## ✅ 해결 — `--mount=type=secret`

BuildKit 1.0+ (Docker 18.09+) 부터 지원. **RUN 명령 도중에만** 컨테이너 내부 임시 파일로 마운트되고, 빌드 끝나면 사라짐.

### Dockerfile

```dockerfile
# syntax=docker/dockerfile:1.7

FROM alpine:latest
RUN --mount=type=secret,id=mytoken \
    TOKEN="$(cat /run/secrets/mytoken)" \
 && echo "사용 중: $TOKEN" \
 && # ... 토큰 사용 명령
```

### 빌드 명령

**파일에서 읽는 경우**:
```bash
echo -n "$MY_SECRET_VALUE" > /tmp/mytoken
docker build --secret id=mytoken,src=/tmp/mytoken -t myimage .
rm /tmp/mytoken
```

**환경변수에서 읽는 경우**:
```bash
docker build --secret id=mytoken,env=MY_SECRET_VALUE -t myimage .
```

### 동작

- 빌드 도중 `/run/secrets/mytoken` 에 임시 파일로 마운트 (RUN 끝나면 unmount)
- **이미지 레이어에 안 들어감** — `docker history` 로 확인해도 안 보임
- BuildKit cache 에도 평문이 아닌 reference 만 저장

---

## 1. 실전 예시 — Private NuGet 피드 인증

```dockerfile
# syntax=docker/dockerfile:1.7
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY *.sln *.csproj NuGet.Config ./
COPY . .

ARG NUGET_USERNAME
RUN --mount=type=secret,id=nuget_token \
    NUGET_TOKEN="$(cat /run/secrets/nuget_token)" \
 && dotnet nuget update source my-private \
      --username "$NUGET_USERNAME" \
      --password "$NUGET_TOKEN" \
      --store-password-in-clear-text \
      --configfile NuGet.Config \
 && dotnet restore

RUN dotnet publish -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine
COPY --from=build /app/publish /app
ENTRYPOINT ["dotnet", "/app/MyApp.dll"]
```

CI 잡:
```yaml
script:
  - echo -n "$NUGET_TOKEN" > /tmp/nuget_token
  - |
    DOCKER_BUILDKIT=1 docker build \
      --secret id=nuget_token,src=/tmp/nuget_token \
      --build-arg NUGET_USERNAME="$NUGET_USERNAME" \
      -t myapp:latest .
after_script:
  - rm -f /tmp/nuget_token
```

- `NUGET_USERNAME` 은 보통 비밀이 아니라서 `--build-arg` 로 OK
- `NUGET_TOKEN` 만 secret 으로 처리

---

## 2. 실전 예시 — Private Git Repo Clone

```dockerfile
# syntax=docker/dockerfile:1.7
FROM alpine/git AS clone
WORKDIR /repo
RUN --mount=type=secret,id=gh_token \
    GH_TOKEN="$(cat /run/secrets/gh_token)" \
 && git clone "https://x-access-token:${GH_TOKEN}@github.com/myorg/private-deps.git" .
```

```bash
docker build --secret id=gh_token,env=GH_TOKEN .
```

빌드 후 이미지에 git URL 의 토큰이 남지 않음.

---

## 3. 실전 예시 — SSH 키로 Git Clone

SSH 키는 별도 mount 타입:

```dockerfile
# syntax=docker/dockerfile:1.7
FROM alpine/git
RUN apk add --no-cache openssh-client
RUN mkdir -p ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN --mount=type=ssh \
    git clone git@github.com:myorg/private-deps.git
```

```bash
# 호스트의 ssh-agent 사용
docker build --ssh default .
```

---

## 4. 검증 — 토큰이 안 박혔는지

```bash
# history 확인
docker history myimage --no-trunc | grep -i token

# 레이어 안 까보기
docker save myimage | tar -xO | grep -ai "ghp_\|secret\|token" | head
```

`--mount=type=secret` 사용했으면 위 결과에 토큰 안 보여야 함.

---

## 5. 흔한 실수

### 5.1 Dockerfile syntax directive 없음

```dockerfile
# 첫 줄에 이게 없으면 BuildKit 1.0 문법만 사용
# syntax=docker/dockerfile:1.7
FROM ...
```

`syntax` directive 없으면 일부 신규 기능 (heredoc, 새 mount 옵션) 동작 안 할 수 있음. 항상 명시 권장.

### 5.2 `DOCKER_BUILDKIT=1` 누락

오래된 Docker (< 23.0) 에서는 BuildKit 이 기본이 아님:

```bash
DOCKER_BUILDKIT=1 docker build ...
```

또는 daemon 설정 (`/etc/docker/daemon.json`):
```json
{ "features": { "buildkit": true } }
```

Docker 23+ 부터는 default 라 신경 X.

### 5.3 secret 을 RUN 밖에서 사용 시도

```dockerfile
# ❌ ENV/ARG 에는 secret 못 씀
ENV TOKEN=$(cat /run/secrets/mytoken)
```

secret 은 **`RUN --mount=type=secret`** 의 그 RUN 안에서만 접근 가능. 이후 stage 에서 다시 쓰려면 또 mount.

### 5.4 secret 파일에 newline 들어감

```bash
echo "$TOKEN" > /tmp/secret    # ❌ \n 추가됨
echo -n "$TOKEN" > /tmp/secret # ✅ newline 없음
```

토큰 비교/사용 시 `\n` 때문에 깨질 수 있음. **`-n` 플래그 필수**.

### 5.5 GitLab CI 의 Masked 변수 길이 제약

GitLab 의 Masked variable 은 **base64 alphabet + 8자 이상** 등 제약이 있음. 토큰 형식이 짧거나 특수문자 들어있으면 Masked 적용 안 되어 로그에 노출. 토큰 발급 시 충분한 길이로.

---

## 6. mount 타입 정리

| type | 용도 | 예 |
|---|---|---|
| `secret` | 빌드 시 일회성 비밀값 | API 토큰, 라이선스 키 |
| `ssh` | SSH agent forwarding | private repo clone |
| `cache` | 빌드 캐시 디렉토리 | npm/pnpm/maven 캐시 |
| `bind` | 호스트 디렉토리 read-only 마운트 | 큰 컨텍스트 일부만 |
| `tmpfs` | 임시 메모리 마운트 | 큰 임시 파일 작업 |

`cache` 도 자주 쓰임:

```dockerfile
RUN --mount=type=cache,target=/root/.npm \
    npm ci
```

빌드 간 npm 캐시 디렉토리 공유 → 다음 빌드부터 빠름.

---

## ✅ 체크리스트

- [ ] Dockerfile 첫 줄에 `# syntax=docker/dockerfile:1.7`
- [ ] 비밀값은 `ARG` 가 아닌 `--mount=type=secret` 으로
- [ ] `echo -n` 으로 newline 없이 임시 파일 작성
- [ ] CI 의 `after_script` 에서 임시 secret 파일 삭제
- [ ] `docker history --no-trunc | grep token` 로 누출 검증
- [ ] Docker 23 미만이면 `DOCKER_BUILDKIT=1` 환경변수
