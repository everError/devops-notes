# Containerized GitLab Runner — Docker Compose 패턴

GitLab Runner 를 호스트에 직접 설치하지 않고 **Docker 컨테이너로** 운영하는 방식. 한 호스트에 여러 그룹/팀의 runner 를 격리해서 띄우기 좋다.

---

## 🎯 왜 컨테이너로?

| 호스트 직접 설치 | 컨테이너 |
|---|---|
| `apt install gitlab-runner` | `docker run gitlab/gitlab-runner` |
| 호스트 OS 의존 | 어디서나 동일 |
| 여러 runner 분리 어려움 | 컨테이너마다 격리 + config 디렉토리 분리 |
| 업데이트 시 호스트 영향 | 이미지 태그 교체로 끝 |

---

## 1. 기본 구성 (compose)

한 host 에서 GitLab + 여러 그룹용 Runner 를 같이 운영하는 예시:

```yaml
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    restart: always
    expose:
      - "80"
      - "443"
      - "22"
    volumes:
      - ./config:/etc/gitlab
      - ./logs:/var/log/gitlab
      - ./data:/var/opt/gitlab
    networks:
      - gitlab-network

  # 그룹별/팀별로 runner 컨테이너를 분리.
  # 각자 다른 config 디렉토리를 마운트해서 설정 격리.
  gitlab-runner-team-a:
    image: gitlab/gitlab-runner:latest
    container_name: gitlab-runner-team-a
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock          # ← 호스트 docker 데몬 접근
      - ./runner-config-team-a:/etc/gitlab-runner          # ← 팀 A 의 config
    networks:
      - gitlab-network
    depends_on:
      - gitlab

  gitlab-runner-team-b:
    image: gitlab/gitlab-runner:latest
    container_name: gitlab-runner-team-b
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./runner-config-team-b:/etc/gitlab-runner          # ← 팀 B 의 config (분리)
    networks:
      - gitlab-network
    depends_on:
      - gitlab

networks:
  gitlab-network:
    name: "gitlab-network"
```

### 핵심 포인트

- 각 runner 컨테이너는 **`/etc/gitlab-runner`** 를 호스트의 별개 디렉토리로 마운트 → config.toml 격리
- **`/var/run/docker.sock`** 마운트 → runner 가 호스트 dockerd 를 사용해서 잡 컨테이너를 띄움 (DooD 패턴, 다음 섹션 참조)

---

## 2. DooD vs DinD — 어느 쪽?

GitLab Runner 의 docker executor 는 잡마다 컨테이너를 띄우는데, 그 컨테이너 안에서 `docker build` 명령을 실행할 방식이 두 가지.

### DooD (Docker-out-of-Docker) ⭐ 권장

호스트의 docker socket 을 잡 컨테이너에 마운트. 잡 컨테이너 안에서 `docker` 명령을 치면 **호스트의 dockerd** 가 실행.

```toml
[runners.docker]
  image = "docker:25.0.3-cli"
  privileged = false
  volumes = [
    "/var/run/docker.sock:/var/run/docker.sock",
    "/host/path/for/deploy:/host/path/for/deploy"   # 배포 잡이 접근할 경로 (선택)
  ]
```

| 장점 | 단점 |
|---|---|
| 가볍다 (별도 데몬 X) | 잡이 호스트 docker 와 같은 권한 (격리 약함) |
| 빌드 캐시 호스트와 공유 | 보안 민감한 멀티테넌트엔 부적합 |
| 호스트 경로 마운트 가능 (deploy 잡에서 활용) | |

### DinD (Docker-in-Docker)

잡 컨테이너 안에서 별도의 dockerd 데몬을 띄움.

```toml
[runners.docker]
  image = "docker:25.0.3-dind"
  privileged = true                                    # ← 필수
```

| 장점 | 단점 |
|---|---|
| 격리 강함 | `privileged: true` 필요 — 보안 위험 |
| 멀티테넌트 친화 | 매 잡마다 dockerd 기동 → 느림 |
| | 빌드 캐시 공유 어려움 (별도 volume 필요) |

→ **사내/단일 팀 용도라면 DooD 가 단순하고 빠름.** Multi-tenant SaaS 만드는 게 아니면 DooD.

---

## 3. config.toml 권장 설정 (DooD + Linux)

config.toml 은 **3단 구조**다.

```
top-level                  ← runner 프로세스 전체 설정 (concurrent, check_interval 등)
└─ [[runners]]             ← 등록된 runner 한 개 (여러 개 가능)
   └─ [runners.docker]     ← 그 runner 의 docker executor 세부 설정
```

전체 예시:

```toml
# ─── Top-level: runner 프로세스 전체 ─────────────────────
concurrent = 4
check_interval = 0

[session_server]
  session_timeout = 1800

# ─── [[runners]]: 등록된 runner 1개 ─────────────────────
[[runners]]
  name = "team-a-runner"
  url = "https://gitlab.example.com"
  clone_url = "https://gitlab.example.com"
  token = "glrt-xxxxxxxxxxxxxxxxxxxx"
  executor = "docker"

  [runners.custom_build_dir]

  # ─── [runners.docker]: 잡 컨테이너 설정 ──────────────
  [runners.docker]
    memory = "4g"
    cpus = "2"
    image = "docker:25.0.3-cli"
    privileged = false
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock",
      "/opt/deploy:/opt/deploy"
    ]
    pull_policy = ["if-not-present", "always"]
    shm_size = 0

  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
```

---

### 3.1 Top-level 옵션

| 옵션 | 의미 | 권장 |
|---|---|---|
| `concurrent` | runner 프로세스 전체에서 **동시 실행할 잡 수**. 모든 `[[runners]]` 의 합산 한도. | matrix 병렬 잡 수 이상. 보통 `2~8` |
| `check_interval` | GitLab 에 새 잡 있는지 polling 주기 (초). `0` 이면 default (3초) | 기본값 OK |
| `[session_server].session_timeout` | 인터랙티브 세션 (web terminal) 타임아웃. 안 쓰면 무시 | 기본값 OK |

⚠️ `concurrent` 가 너무 작으면 matrix 병렬이 직렬로 풀리고, 너무 크면 호스트 자원 (메모리/CPU) 부족으로 OOM. matrix 잡 수 + 약간 여유 정도가 적절.

---

### 3.2 `[[runners]]` 블록 옵션

| 옵션 | 의미 | 비고 |
|---|---|---|
| `name` | runner 식별자. GitLab UI 에 표시됨 | 자유 |
| `url` | GitLab 서버 base URL | external_url 과 일치해야 인증 흐름이 깔끔 |
| `clone_url` | runner 가 git clone 시 사용할 URL. **`url` 과 다를 때만 명시** | 아래 ⚠️ 참조 |
| `token` | runner 인증 토큰 (`glrt-` prefix, GitLab 16+) | **유출되면 즉시 revoke** |
| `executor` | 잡 실행 방식 | `docker` / `shell` / `kubernetes` 등 |
| `[runners.custom_build_dir]` | 빌드 디렉토리 커스터마이징 옵션 블록 | 기본 비워둠 |
| `[runners.cache]` | 잡 간 캐시 저장소 (S3, GCS 등) | 안 쓰면 빈 블록만 |

#### ⚠️ `clone_url` 가 필요한 경우

대부분 `url` 만 있으면 되고 `clone_url` 은 생략. 단 다음 상황에서 필요:

- GitLab `external_url` 이 **http** 인데 호스트 nginx 가 **https 로 redirect** 해서 인증 헤더가 사라지는 경우
- runner 가 보는 GitLab URL 과 외부 GitLab URL 이 다른 경우 (예: 컨테이너명 vs 도메인)
- Job clone 시 `Authentication failed` 가 떠도 그 외 인증은 정상인 경우

```toml
url = "http://gitlab.internal"          # GitLab API 호출용
clone_url = "https://gitlab.example.com" # git clone 만 https 로
```

근본 해결은 `external_url` 을 https 로 통일하는 것이지만, 인프라 정리 전 임시 우회로 유용.

#### `glrt-` 토큰 형식

GitLab 16+ 부터 runner 등록 토큰은 `glrt-` prefix:

```
glrt-t2_zth7Vw1nvGWsyiFoSpmG
```

이전 버전의 짧은 registration token 과 다른 메커니즘 (Authentication Token). 이 토큰은:
- runner 자체의 ID/credential 역할
- 노출되면 **다른 호스트가 같은 runner 로 가장** 가능 → 즉시 revoke 필요
- config.toml 외부 접근 (호스트 다른 사용자, 백업 등) 신경 쓰기

---

### 3.3 `[runners.docker]` 블록 옵션

잡 컨테이너 자체에 적용되는 설정.

| 옵션 | 권장값 | 의미 / 이유 |
|---|---|---|
| `image` | `docker:25.0.3-cli` (DooD) / `docker:25.0.3-dind` (DinD) | `.gitlab-ci.yml` 의 `image:` 가 명시 안 됐을 때 사용할 기본 이미지. CI 잡이 docker 명령을 칠 거라면 docker CLI 가 들어있어야 함. compose v2 (`docker compose`) 도 최근 docker:cli 이미지에 포함됨 |
| `privileged` | `false` (DooD) / `true` (DinD) | 잡 컨테이너의 권한. DinD 는 컨테이너 안에서 데몬을 띄우니 privileged 필수, DooD 는 host socket 만 쓰니 불필요 |
| `volumes` | socket + 필요한 호스트 경로 (1:1 매핑 권장) | 잡 컨테이너에 마운트할 호스트 경로. 첫 entry 인 docker.sock 은 DooD 의 핵심 |
| `pull_policy` | `["if-not-present", "always"]` 배열 | 잡 시작 시 image 를 어떻게 가져올지. 배열이면 **순서대로 시도**. 호스트에 있으면 재사용 → 없으면 pull. `"always"` 단독은 매번 pull 받아 느림. `"if-not-present"` 단독은 image 갱신 안 됨 |
| `memory` | `"4g"` 정도 | 잡당 RAM 제한. 빌드 잡은 OOM 잘 나니 충분히. nx/webpack/.NET publish 같은 작업은 1.5–2 GB 쉽게 사용 |
| `cpus` | `"2"` 정도 | 잡당 CPU 제한 |
| `shm_size` | `0` (기본) | 공유 메모리 (`/dev/shm`). 0 이면 default (64MB). Chrome headless 같은 거 돌릴 때만 키움 |
| `network_mode` | (생략) | 잡 컨테이너의 network. 기본 `bridge`. 호스트 network 에 노출하려면 `"host"` |
| `extra_hosts` | (필요 시) | 잡 컨테이너의 `/etc/hosts` 에 추가할 entry. 사내 도메인 강제 매핑 |

#### `volumes` — 1:1 매핑 권장

호스트와 잡 컨테이너가 같은 경로를 보도록 1:1 매핑이 깔끔:

```toml
volumes = [
  "/var/run/docker.sock:/var/run/docker.sock",
  "/opt/deploy:/opt/deploy"             # 호스트 경로 == 잡 컨테이너 경로
]
```

이러면 `.gitlab-ci.yml` 에서 `cd /opt/deploy && docker compose pull` 같이 **호스트 경로 그대로** 사용 가능 (헷갈림 ↓).

만약 다르게 매핑하면:
```toml
"/opt/deploy:/builds/deploy"   # 컨테이너에서는 /builds/deploy 로 보임
```
→ CI yml 에서 `cd /builds/deploy` 로 적어야 하고, 직관성 떨어짐.

#### DooD 에서 `privileged: false` 가 핵심

```toml
image = "docker:25.0.3-cli"   # CLI only
privileged = false            # 권한 불필요
volumes = ["/var/run/docker.sock:/var/run/docker.sock"]
```

socket 만 마운트해서 호스트 dockerd 를 사용. privileged 필요 X. 보안상 더 안전.

DinD 와 헷갈리면 `image = "docker:dind"` + `privileged = false` 같은 잘못된 조합이 나올 수 있음 — 이러면 DinD 가 데몬 못 띄워서 잡 안에서 docker 명령이 fail.

#### `pull_policy` 동작 정리

| 값 | 의미 |
|---|---|
| `"always"` | 매 잡마다 image pull. 항상 최신이지만 느리고 registry 부하 |
| `"if-not-present"` | 호스트에 있으면 그대로 사용, 없을 때만 pull. 빠르지만 image 가 갱신돼도 못 받음 |
| `"never"` | 절대 pull 안 함. 호스트에 미리 빌드해둔 이미지만 사용 |
| `["if-not-present", "always"]` | **순서대로 시도** — 처음엔 캐시 사용, 캐시 miss 면 pull 로 fallback. registry 가 일시적으로 unreachable 일 때도 캐시로 넘어감 |

배열 폴백은 단순한 "재시도" 가 아니라 **복수 정책의 우선순위**. 운영 안정성 + 빠른 시작 둘 다 원하면 `["if-not-present", "always"]`.

권장 매트릭스:
- 운영 안정성 + 빠른 시작: `["if-not-present", "always"]`
- 항상 최신 image 보장 필요 (digest 까지): `"always"` 단독 (느림 감수)
- 호스트에서 직접 빌드한 image 만 사용 (registry 없음): `"never"`

---

### 3.4 변경 후 적용 — `restart` 필요

config.toml 을 수정하면 runner 가 자동 reload **하지 않는다.** 컨테이너 재시작 필요:

```bash
docker restart gitlab-runner-team-a
```

또는 명시적 verify 로 등록 상태 확인:

```bash
docker exec gitlab-runner-team-a gitlab-runner verify
```

verify 출력에 `is alive!` 가 보이면 정상.

---

## 4. Runner 등록 — 컨테이너 안에서 실행

호스트에 `gitlab-runner` 명령이 없으니 컨테이너 안에서 register:

```bash
docker exec -it gitlab-runner-team-a gitlab-runner register \
  --url https://gitlab.example.com \
  --token <GitLab UI 에서 받은 토큰> \
  --executor docker \
  --docker-image docker:25.0.3-cli \
  --description "team A deploy runner" \
  --tag-list "team-a-deploy" \
  --non-interactive
```

→ 호스트의 `./runner-config-team-a/config.toml` 에 자동으로 `[[runners]]` 블록이 추가됨. 그 후 위 권장 설정 (memory, volumes 등) 으로 보강.

### 토큰 받는 위치 (GitLab UI)

| 범위 | 경로 |
|---|---|
| Instance | Admin → CI/CD → Runners → New instance runner |
| Group | Group → Settings → CI/CD → Runners → New group runner |
| Project | Project → Settings → CI/CD → Runners → New project runner |

토큰 형식: GitLab 16+ 부터 `glrt-` prefix.

---

## 5. 흔한 함정

### 5.1 호스트 경로가 잡 컨테이너에 안 보임

`/etc/gitlab-runner/config.toml` 의 `volumes` 는 **잡 컨테이너에 마운트할 경로**. runner 컨테이너가 보는 경로가 아님.

socket 이 호스트 dockerd 를 가리키니, runner 가 컨테이너 안에 있어도 dockerd 에 "**호스트의** /opt/deploy 를 잡 컨테이너의 /opt/deploy 로 마운트해라" 라고 명령. 따라서:

```toml
volumes = [
  "/opt/deploy:/opt/deploy"   # 호스트 경로 그대로 적기
]
```

runner 컨테이너 자체에 `/opt/deploy` 가 있을 필요 없음.

### 5.2 image 가 dind 인데 privileged 가 false

```toml
image = "docker:dind"
privileged = false   # ❌ dind 는 privileged 필요
```

→ DinD 쓸 거면 `true`. 또는 image 를 `docker:cli` 로 바꿔서 DooD.

### 5.3 docker compose v1 vs v2

`apk add docker-compose` 로 설치되는 알파인 패키지는 **v1** (Python 기반). v2 는 `apk add docker-cli-compose` 또는 base image 에 이미 포함된 경우가 많음.

확인:
```bash
docker run --rm <image> docker compose version    # v2
docker run --rm <image> docker-compose version    # v1
```

CI 스크립트에서 `docker compose` (공백) 와 `docker-compose` (하이픈) 는 **다른 명령**. 어느 쪽을 쓰는지 일관성 유지.

### 5.4 등록 후 Job clone 인증 실패

```
fatal: Authentication failed for 'http://gitlab.example.com/...'
```

원인 후보:
1. **Group runner 지만 프로젝트에 enable 안 됨** — Project → Settings → CI/CD → Runners 에서 group runner 활성화
2. **Protected runner + non-protected branch** — runner 의 `Protected` 옵션이 켜져있는데 push 한 브랜치가 protected 가 아님
3. **CI Job Token allowlist 차단** — Project → Settings → CI/CD → Token Access
4. **GitLab `external_url` 과 runner 가 보는 URL 불일치** — `external_url` 이 https 인데 runner config 에 http URL 등록 등. 그럴 땐 `clone_url` 옵션으로 override:
   ```toml
   [[runners]]
     url = "https://gitlab.example.com"
     clone_url = "https://gitlab.example.com"
   ```

---

## 6. Runner 운영 명령

```bash
# 상태 확인
docker exec gitlab-runner-team-a gitlab-runner verify

# 등록된 runner 목록
docker exec gitlab-runner-team-a gitlab-runner list

# 특정 runner 제거
docker exec gitlab-runner-team-a gitlab-runner unregister --name "team-a-runner"

# config 재로드 (shell 등록을 바꿨을 때)
docker restart gitlab-runner-team-a

# 로그
docker logs -f gitlab-runner-team-a
```

---

## ✅ 체크리스트

- [ ] runner 컨테이너마다 `/etc/gitlab-runner` 별도 디렉토리 마운트
- [ ] DooD 사용 (멀티테넌트 아니면) — `image: docker:cli` + `privileged: false` + socket 마운트
- [ ] `concurrent` 값을 매트릭스 잡 수 이상으로
- [ ] `pull_policy = ["if-not-present", "always"]`
- [ ] 배포 잡이 호스트 경로 사용한다면 `volumes` 에 1:1 매핑
- [ ] Tag 명시 (`tag-list`) — 잡과 매칭
- [ ] (그룹 runner) 프로젝트별 enable 확인
