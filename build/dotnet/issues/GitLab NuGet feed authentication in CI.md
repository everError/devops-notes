# GitLab NuGet 피드 — CI(Docker 빌드) 에서 인증/HTTP 오류 트러블슈팅

GitLab Package Registry 의 NuGet 피드를 .NET 프로젝트의 사내 패키지 소스로 사용할 때, **로컬에서는 잘 되는데 GitLab CI 의 Docker 빌드에서는 `dotnet restore` 가 실패** 하는 케이스 모음.

---

## 🔥 자주 보는 에러 4가지

### 1) `error NU1302: ... contains an 'HTTP' service index resource endpoint`

```
error NU1302: You are using a NuGet source 'https://.../packages/nuget/index.json'
that contains an 'HTTP' service index resource endpoint:
'http://.../packages/nuget/download/<pkg>/index.json'.
This is insecure and not recommended.
To allow HTTP resources, you must explicitly set 'allowInsecureConnections' to true
in your NuGet.Config file.
```

#### 원인
- 피드의 `index.json` 자체는 https 인데, 응답 안의 패키지 다운로드 endpoint URL 들이 **http** 로 발급된다.
- GitLab 컨테이너의 `external_url` 이 `http://...` 로 설정돼 있을 때 발생. GitLab 이 자기 base URL 을 그대로 응답에 박는다.
- NuGet 6.x 부터 mixed http/https 를 보안상 거부.

#### 해결
**A. 단기 우회** — `NuGet.Config` 에 `allowInsecureConnections="true"` 추가:

```xml
<add key="my-gitlab"
     value="https://gitlab.example.com/api/v4/projects/ID/packages/nuget/index.json"
     allowInsecureConnections="true" />
```

⚠️ `dotnet nuget update source` 명령은 이 attribute 를 보존하지 못한다. CI 에서 `update source` 를 호출한다면 **명령 자체에 플래그를 추가**해야 한다:

```bash
dotnet nuget update source my-gitlab \
  --username "$NUGET_USER" \
  --password "$NUGET_TOKEN" \
  --store-password-in-clear-text \
  --allow-insecure-connections \
  --configfile NuGet.Config
```

**B. 근본 해결** — GitLab 의 `external_url` 을 https 로 통일:

`/etc/gitlab/gitlab.rb`:

```ruby
external_url 'https://gitlab.example.com'

# 앞단 reverse proxy 가 SSL 종료, GitLab 컨테이너는 평문 80
nginx['listen_port'] = 80
nginx['listen_https'] = false
```

호스트 nginx vhost 는 다음 헤더를 보내야 한다:

```nginx
proxy_set_header X-Forwarded-Proto https;
proxy_set_header X-Forwarded-Ssl on;
```

적용:
```bash
docker exec -it gitlab gitlab-ctl reconfigure
```

#### 확인
```bash
curl -s https://gitlab.example.com/api/v4/projects/ID/packages/nuget/index.json \
  | grep -o '"@id":"[^"]*"' | head -3
```
응답의 `@id` 가 모두 `https://...` 로 시작하면 OK.

---

### 2) `Response status code does not indicate success: 401 (Unauthorized)`

```
Retrying 'FindPackagesByIdAsync' for source 'http://.../download/<pkg>/index.json'.
Response status code does not indicate success: 401 (Unauthorized).
...
error NU1301: Failed to retrieve information about '<Pkg>' from remote source ...
  Response status code does not indicate success: 401 (Unauthorized).
```

#### 원인 — 토큰 종류별로 username 규칙이 다름

GitLab 은 토큰 종류마다 Basic Auth 의 username 규칙이 다르다:

| 토큰 종류 | username | 비고 |
|---|---|---|
| **Personal Access Token (PAT)** | 본인 GitLab 사용자명 (예: `john`) | User Settings → Access Tokens |
| **Project Access Token** | 토큰의 *Token name* | Project → Settings → Access Tokens — 일부 GitLab 버전에서 Package Registry 인증과 호환 문제 보고됨 |
| **Deploy Token** | 발급 시 정한 username (또는 자동: `gitlab+deploy-token-{N}`) | Project → Settings → Repository → Deploy tokens — **CI 에서 가장 안정적** |
| **CI Job Token** | `gitlab-ci-token` | 패스워드는 `$CI_JOB_TOKEN`. 단, 자기 프로젝트의 Package Registry 가 아닌 경우 권한 제한 |

또한 권한 측면:
- Project Access Token 은 **Role 이 `Guest` 면 Package Registry 읽기 거부됨** (Private 프로젝트 기준). `Reporter` 이상이어야 함.
- Deploy Token 은 **`read_package_registry` scope** 가 명시적으로 켜져 있어야 함.
- `api` / `read_api` scope 가 있어도 role/scope 가 부족하면 401.

#### 해결 — Deploy Token 사용 (CI 표준)

1. Project → Settings → Repository → Deploy tokens → **Add deploy token**
2. Name: `nuget-ci`
3. Username: 비워두면 `gitlab+deploy-token-{N}` 자동 생성. 직접 입력해도 OK.
4. Scopes: ✅ **`read_package_registry`** (push 도 한다면 `write_package_registry` 추가)
5. Create → 발급된 username + token 둘 다 즉시 복사 (token 은 한 번만 표시됨)

CI/CD Variables 에 등록:
- `NUGET_USERNAME` = 발급된 username
- `NUGET_TOKEN` = 발급된 token (Masked + Protected)

⚠️ username 에 `+` 가 들어있으므로 **"Expand variable reference" 옵션은 끈다** (그렇지 않으면 변수 치환 시도하다 깨질 수 있음).

#### 검증
```bash
# index.json 은 익명 접근 허용일 수 있어서 download endpoint 로 검증
curl -i -L -u "$NUGET_USERNAME:$NUGET_TOKEN" \
  https://gitlab.example.com/api/v4/projects/ID/packages/nuget/download/<pkg-lowercase>/index.json
```
`HTTP/1.1 200 OK` + 버전 목록 JSON 이 나와야 한다.

---

### 3) `Authorization` 헤더가 redirect 따라가다 사라져서 401

#### 증상
- `index.json` 은 200 으로 잘 받음 (인증 OK)
- 그런데 패키지 다운로드 단계에서 401 이 무한 retry

#### 원인
응답의 download endpoint URL 이 `http://...` 인데 (#1 의 부산물), 앞단 nginx 가 http→https **301 redirect** 를 건다. NuGet 클라이언트가 redirect 따라가는데, Basic Auth 헤더가 redirect 시 드롭되어 인증 헤더 없이 요청 → 401.

curl 로 동일 증상 재현:
```bash
curl -i -u "$NUGET_USER:$NUGET_TOKEN" \
  http://gitlab.example.com/api/v4/projects/ID/packages/nuget/download/<pkg>/index.json
# HTTP/1.1 301 Moved Permanently
# Location: https://...
```

#### 해결
근본 해결은 #1 의 **B. external_url 을 https 로 통일** 하는 것. 그러면 응답 URL 이 처음부터 https 로 발급되어 redirect 자체가 없다.

임시 우회로 NuGet.Config 의 피드 URL 을 http 로 맞춰서 redirect 를 회피하는 방법도 있지만 권장하지 않는다 (보안 + 향후 https 전환 시 다시 깨짐).

---

### 4) Docker 빌드에서 토큰이 이미지 레이어에 박힘

#### 안티패턴
```dockerfile
ARG NUGET_TOKEN
RUN dotnet nuget update source ... --password "$NUGET_TOKEN" ...
```

`docker history <image>` 에서 ARG 값이 그대로 노출된다. CI 변수에 Masked 라도 이미지 레이어에는 박힘.

#### 해결 — BuildKit secret 마운트

`Dockerfile`:
```dockerfile
# syntax=docker/dockerfile:1.7
ARG NUGET_USERNAME
RUN --mount=type=secret,id=nuget_token \
    NUGET_TOKEN="$(cat /run/secrets/nuget_token)" \
 && dotnet nuget update source my-gitlab \
      --username "$NUGET_USERNAME" \
      --password "$NUGET_TOKEN" \
      --store-password-in-clear-text \
      --allow-insecure-connections \
      --configfile NuGet.Config \
 && dotnet restore
```

CI 잡:
```yaml
script:
  - echo -n "$NUGET_TOKEN" > /tmp/nuget_token
  - |
    DOCKER_BUILDKIT=1 docker build \
      --secret id=nuget_token,src=/tmp/nuget_token \
      --build-arg NUGET_USERNAME="$NUGET_USERNAME" \
      -t my-image:$CI_COMMIT_SHORT_SHA .
after_script:
  - rm -f /tmp/nuget_token
```

- secret 은 RUN 도중에만 `/run/secrets/nuget_token` 에 마운트되고, 이미지 레이어에 남지 않음.
- username 은 일반 build-arg 로도 충분 (보통 비밀이 아님).

---

## 🔍 진단 체크리스트

증상별 빠른 확인 순서:

1. **NU1302 (HTTP endpoint)** → GitLab 의 `external_url` 확인. `index.json` 응답의 `@id` 들이 https 인가?
2. **401** → 사용 중인 토큰 종류 / username 규칙 / scope / role 점검. `curl -L -u user:token download_url` 로 직접 검증.
3. **로컬은 되는데 CI 만 깨짐** → 로컬 `NuGet.Config` (`%AppData%\NuGet\NuGet.Config` 또는 `~/.nuget/NuGet.Config`) 를 열어 어떤 username/credential 로 동작 중인지 확인. CI 에 같은 형식으로 옮긴다.
4. **Central Package Management 사용 중 + warning NU1507** → `<packageSourceMapping>` 으로 사내 패턴(`MyOrg.*`)과 `nuget.org` 를 분리하면 NU1507 제거 + 빌드 속도 개선.
5. **`failed to solve` 만 보이고 dotnet 출력이 안 보임** → `docker build` 에 `--progress=plain` 추가. CI 잡의 Raw 로그 다운로드.

---

## 📝 권장 NuGet.Config 템플릿 (CI/Docker 용)

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
    <add key="my-gitlab"
         value="https://gitlab.example.com/api/v4/projects/ID/packages/nuget/index.json"
         allowInsecureConnections="true" />
  </packageSources>
  <packageSourceMapping>
    <packageSource key="my-gitlab">
      <package pattern="MyOrg.*" />
    </packageSource>
    <packageSource key="nuget.org">
      <package pattern="*" />
    </packageSource>
  </packageSourceMapping>
</configuration>
```

- `allowInsecureConnections` 는 GitLab `external_url` 이 https 로 정리되면 제거 가능.
- credential 은 NuGet.Config 에 박지 않고, CI 에서 `dotnet nuget update source` 로 주입한다 (위 #4 참조).

---

## ✅ 정상 동작 확인 명령

```bash
# 1) 피드 자체
curl -s https://gitlab.example.com/api/v4/projects/ID/packages/nuget/index.json | head -5

# 2) 인증 (다운로드 endpoint)
curl -i -L -u "$NUGET_USER:$NUGET_TOKEN" \
  https://gitlab.example.com/api/v4/projects/ID/packages/nuget/download/<pkg-lowercase>/index.json

# 3) Docker 빌드 (로컬 재현)
echo -n "$NUGET_TOKEN" > /tmp/nuget_token
DOCKER_BUILDKIT=1 docker build \
  --secret id=nuget_token,src=/tmp/nuget_token \
  --build-arg NUGET_USERNAME="$NUGET_USERNAME" \
  --progress=plain \
  --no-cache \
  -t test:1 .
```

---

## 🔗 연관 문서

- [BuildKit secrets](../../../containers/docker/notes/buildkit%20secrets.md) — 토큰을 이미지 레이어에 박지 않고 안전하게 주입
- [Multi-target Dockerfile](../../../containers/docker/notes/multi-target%20dockerfile.md) — 모노레포에서 NuGet restore 캐시 공유
- [Monorepo pipeline strategy](../../../cicd/gitlab/pipeline/monorepo%20pipeline%20strategy.md) — CI 잡 구조와 함께 보기
