# 모노레포 GitLab CI 파이프라인 전략

여러 서비스(예: backend 여러 개 + frontend) 가 한 저장소에 있을 때, **변경된 부분만 빌드하고 한 번에 배포** 하는 패턴.

---

## 1. 핵심 아이디어

```
push
  ↓
[변경된 경로 감지] ── rules:changes
  ↓
[필요한 빌드 잡만 실행]
  ↓
[스테이지: build → deploy]
  ↓
[deploy 는 항상 :latest 로 받기]
```

매 push 마다 모든 서비스를 다시 빌드하면 시간/자원 낭비. 그렇다고 deploy 가 SHA 태그로만 받으면, 일부만 빌드된 상황에서 다른 서비스의 SHA 이미지가 없어 404. 이 두 문제를 동시에 푸는 게 목표.

---

## 2. `rules:changes` 로 부분 빌드

```yaml
build_backend:
  stage: build
  rules:
    - if: '$CI_PIPELINE_SOURCE == "web" && $CI_COMMIT_BRANCH == "main"'
      # UI 의 "Run pipeline" 으로 수동 실행 시 → 항상 빌드
    - if: '$CI_COMMIT_BRANCH == "main"'
      changes:
        - services/backend/**/*
        - .gitlab-ci.yml
  script:
    - ./build-backend.sh

build_web:
  stage: build
  rules:
    - if: '$CI_PIPELINE_SOURCE == "web" && $CI_COMMIT_BRANCH == "main"'
    - if: '$CI_COMMIT_BRANCH == "main"'
      changes:
        - apps/web/**/*
        - shared/**/*
        - .gitlab-ci.yml
  script:
    - ./build-web.sh
```

### 동작

| 변경 위치 | build_backend | build_web | deploy |
|---|---|---|---|
| backend 코드 | ✅ | ❌ skip | ✅ |
| web 코드 | ❌ skip | ✅ | ✅ |
| 둘 다 | ✅ | ✅ | ✅ |
| README | ❌ | ❌ | ✅ (no-op) |

### 수동 트리거 룰을 첫 번째에 둬야 하는 이유

`rules` 는 위에서부터 첫 매치만 적용된다. UI 의 "Run pipeline" 으로 강제 빌드를 원할 때 `changes` 가 매치 안 되면 그대로 skip 되어 강제 빌드가 안 된다. `$CI_PIPELINE_SOURCE == "web"` 룰을 위에 두면, 수동 실행 시에는 changes 무시하고 무조건 빌드.

`CI_PIPELINE_SOURCE` 의 가능한 값:
- `push` — git push 로 트리거
- `web` — UI 의 "Run pipeline" 버튼
- `schedule` — Pipeline schedule
- `api`, `trigger`, `merge_request_event` 등

---

## 3. Build/Deploy 사이의 함정 — 부분 빌드 + SHA 태그

흔한 실수: 모든 서비스를 `$CI_COMMIT_SHORT_SHA` 태그로 빌드/푸시하고, deploy 도 그 SHA 로 받기.

```yaml
variables:
  IMAGE_TAG: "${CI_COMMIT_SHORT_SHA}"
```

```yaml
deploy:
  script:
    - docker compose pull   # IMAGE_TAG 환경변수 사용
```

```yaml
# docker-compose.yml
services:
  backend:
    image: registry/backend:${IMAGE_TAG}
  web:
    image: registry/web:${IMAGE_TAG}
```

이 상태에서 web 만 변경된 push 가 발생하면:
- `build_web` 만 실행 → `web:abc1234` 태그로 push ✅
- `build_backend` skip → `backend:abc1234` 태그는 어디에도 없음 ❌
- `deploy` 의 `docker compose pull` 이 `backend:abc1234` 받으려다 **404 not found**.

### 해결 — deploy 는 `:latest` 강제

빌드 잡은 두 태그(SHA + latest)를 같이 푸시하고, deploy 는 항상 latest 를 받는다.

```yaml
build_backend:
  script:
    - |
      docker build \
        -t "$REGISTRY/backend:$CI_COMMIT_SHORT_SHA" \
        -t "$REGISTRY/backend:latest" \
        .
    - docker push "$REGISTRY/backend:$CI_COMMIT_SHORT_SHA"
    - docker push "$REGISTRY/backend:latest"

deploy:
  script:
    - cd /opt/myapp
    - export IMAGE_TAG=latest    # ← 강제
    - docker compose pull
    - docker compose up -d --remove-orphans
```

이러면 부분 빌드 + 부분 갱신 + 다른 서비스는 직전 latest 그대로 동작.

### 트레이드오프

- **장점**: 단순. 항상 동작.
- **단점**:
  - rollback 어려움 — `latest` 가 항상 갱신되므로 "어제 그 상태로" 돌아가려면 SHA 태그를 수동으로 찾아 compose 의 image 줄을 임시 교체해야 함.
  - audit log 약함 — "지금 떠있는 web 컨테이너가 어느 commit 이냐" 추적이 한 단계 더 필요 (`docker inspect` 로 image digest → registry 에서 어떤 SHA 와 같은 digest인지 매칭).

### 더 정교한 패턴 (선택)

태그 두 개 외에 **environment 별 채널** 추가:

| 태그 | 의미 |
|---|---|
| `:abc1234` | 특정 commit |
| `:latest` | 가장 최근 빌드 |
| `:stable` | 수동 승격된 안정 빌드 (rollback 용) |
| `:dev`, `:staging`, `:prod` | environment 채널 |

이건 운영 부담이 늘어나니 **필요해진 시점에** 도입.

---

## 4. Build 캐시 — `--cache-from` 패턴

빌드 캐시를 같은 registry 에 보관하면 다음 빌드가 빨라진다.

```yaml
build_backend:
  script:
    - |
      docker build \
        --cache-from "$REGISTRY/backend:cache" \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        -t "$REGISTRY/backend:$CI_COMMIT_SHORT_SHA" \
        -t "$REGISTRY/backend:latest" \
        -t "$REGISTRY/backend:cache" \
        .
    - docker push "$REGISTRY/backend:$CI_COMMIT_SHORT_SHA"
    - docker push "$REGISTRY/backend:latest"
    - docker push "$REGISTRY/backend:cache"
```

- `--build-arg BUILDKIT_INLINE_CACHE=1` — 이미지 자체에 캐시 메타데이터를 인라인. 별도 cache export 불필요.
- `--cache-from` — 이전 빌드의 캐시 이미지에서 레이어 재사용.
- 첫 빌드 시 `:cache` 가 없으면 단순히 무시되고 (경고만) 캐시 없이 빌드. 정상.

⚠️ 일부 BuildKit 버전에서는 `:cache` not found 가 fatal 이 되는 케이스가 보고된다. 그땐 첫 빌드 한 번만 `--cache-from` 빼고 통과시키거나, registry 에 빈 cache 이미지를 미리 push.

---

## 5. matrix 로 비슷한 잡 병렬화

같은 빌드 로직을 여러 서비스에 적용할 때 잡 정의를 복붙하지 말고 `parallel:matrix` 사용.

```yaml
build_backend:
  stage: build
  parallel:
    matrix:
      - SERVICE: api-orders
      - SERVICE: api-billing
      - SERVICE: api-inventory
  script:
    - |
      docker build \
        --target "$SERVICE" \
        -t "$REGISTRY/$SERVICE:$CI_COMMIT_SHORT_SHA" \
        -t "$REGISTRY/$SERVICE:latest" \
        .
    - docker push "$REGISTRY/$SERVICE:$CI_COMMIT_SHORT_SHA"
    - docker push "$REGISTRY/$SERVICE:latest"
```

- `--target` 으로 단일 Dockerfile 의 여러 stage 를 분기 (참조: `containers/docker/notes/multi-target dockerfile.md`)
- 잡 3개가 동시에 실행 → 빌드 시간 단축.
- 동시 실행 수는 runner 의 `concurrent` 값에 의해 제한됨.

---

## 6. 빌드 컨텍스트가 둘 이상일 때 — `Dockerfile.dockerignore`

모노레포에서 backend / frontend 가 서로 다른 Dockerfile + 다른 빌드 컨텍스트를 가질 때, 컨텍스트 루트의 `.dockerignore` 하나로는 부족하다.

BuildKit 1.5+ (Docker 25+) 는 **Dockerfile 별 ignore 파일**을 지원:

```
repo/
├── services/
│   ├── backend/
│   │   ├── Dockerfile
│   │   └── Dockerfile.dockerignore   ← backend 빌드용
│   └── web/
│       ├── Dockerfile
│       └── Dockerfile.dockerignore   ← web 빌드용
```

또는 빌드 컨텍스트 자체를 한 단계 위로 올리고 컨텍스트 루트에 `.dockerignore` 를 두는 방식. 어느 쪽이든 **컨텍스트 안에 들어가지 말아야 할 디렉토리** (예: 다른 서비스의 거대한 `node_modules`) 를 명시하면 빌드 속도/크기 차이 큼.

---

## 7. 정리 — 권장 골격

```yaml
stages:
  - build
  - deploy

variables:
  REGISTRY: "registry.example.com/myorg"

# 공통 로그인
.registry_login: &registry_login
  - echo "$REGISTRY_PASSWORD" | docker login "$REGISTRY" -u "$REGISTRY_USER" --password-stdin

build_backend:
  stage: build
  rules:
    - if: '$CI_PIPELINE_SOURCE == "web" && $CI_COMMIT_BRANCH == "main"'
    - if: '$CI_COMMIT_BRANCH == "main"'
      changes:
        - services/**/*
        - .gitlab-ci.yml
  before_script:
    - *registry_login
  script:
    - |
      docker build \
        --target "$SERVICE" \
        --cache-from "$REGISTRY/$SERVICE:cache" \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        -t "$REGISTRY/$SERVICE:$CI_COMMIT_SHORT_SHA" \
        -t "$REGISTRY/$SERVICE:latest" \
        -t "$REGISTRY/$SERVICE:cache" \
        services/
    - docker push "$REGISTRY/$SERVICE:$CI_COMMIT_SHORT_SHA"
    - docker push "$REGISTRY/$SERVICE:latest"
    - docker push "$REGISTRY/$SERVICE:cache"
  parallel:
    matrix:
      - SERVICE: api-orders
      - SERVICE: api-billing

build_web:
  stage: build
  rules:
    - if: '$CI_PIPELINE_SOURCE == "web" && $CI_COMMIT_BRANCH == "main"'
    - if: '$CI_COMMIT_BRANCH == "main"'
      changes:
        - apps/web/**/*
        - .gitlab-ci.yml
  before_script:
    - *registry_login
  script:
    - docker build -t "$REGISTRY/web:latest" apps/web
    - docker push "$REGISTRY/web:latest"

deploy:
  stage: deploy
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
  before_script:
    - *registry_login
  script:
    - cd /opt/myapp
    - export IMAGE_TAG=latest
    - docker compose pull
    - docker compose up -d --remove-orphans
    - docker image prune -f
```

---

## ✅ 체크리스트

- [ ] `rules:changes` 의 첫 룰에 `$CI_PIPELINE_SOURCE == "web"` 또는 `"schedule"` 매치 추가 (수동 실행 대비)
- [ ] 모든 빌드 잡은 `:latest` 태그를 함께 푸시
- [ ] deploy 잡은 `IMAGE_TAG=latest` 로 강제
- [ ] 비슷한 서비스들은 `parallel:matrix` 로 병렬화
- [ ] 두 개 이상의 빌드 컨텍스트가 있으면 `Dockerfile.dockerignore` 또는 컨텍스트 루트의 `.dockerignore` 분리
- [ ] `--cache-from` + `BUILDKIT_INLINE_CACHE=1` 로 캐시 활용
