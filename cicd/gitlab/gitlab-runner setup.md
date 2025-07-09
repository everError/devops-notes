# GitLab 그룹 러너 구성 및 테스트 정리

## 1. 환경 구성 개요

- **GitLab 설치 환경**: Docker Compose를 사용하여 GitLab CE 컨테이너로 구성
- **GitLab Runner**: 별도의 컨테이너로 실행되며, 그룹에 연결
- **GitLab 주소**: [http://your.gitlab.server](http://your.gitlab.server)
- **목표**: 특정 그룹에 등록된 Runner가 `.gitlab-ci.yml` 파이프라인을 실행할 수 있도록 설정

---

## 2. GitLab 및 GitLab Runner 컨테이너 설정

### 2.1 `docker-compose.yml`

```yaml
version: "3.8"

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

  gitlab-runner:
    image: gitlab/gitlab-runner:latest
    container_name: gitlab-runner
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./runner-config:/etc/gitlab-runner
    networks:
      - gitlab-network

networks:
  gitlab-network:
    name: "gitlab-network"
```

### 2.2 컨테이너 실행

```bash
docker compose up -d
```

---

## 3. GitLab 그룹 러너 등록

### 3.1 토큰 확인

- GitLab 그룹 > Build > Runners > New group runner

### 3.2 Runner 등록

```bash
docker exec -it gitlab-runner gitlab-runner register
```

입력 예시:

- GitLab URL: `http://your.gitlab.server/`
- Token: (복사한 그룹 토큰)
- Description: `group-runner`
- Tags: `group_tag`
- Executor: `docker`
- Default Docker image: `alpine:latest`

### 3.3 `config.toml` 설정 확인

```toml
[[runners]]
  name = "group-runner"
  url = "http://your.gitlab.server/"
  token = "등록된 토큰"
  executor = "docker"
  [runners.custom_build_dir]

  [runners.docker]
    memory = "2g"
    cpus = "1.5"
    image = "docker:25.0.3-dind"                       # Job 실행용 기본 컨테이너 이미지
    privileged = true                             # Docker-in-Docker나 루트 권한 필요한 경우 true
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock",
      "/var/services/dev-release:/dev-release"
    ]
    pull_policy = "if-not-present"
    shm_size = 0

  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]

```

### 3.4 Git 인증 문제 해결 (clone_url 설정)

```toml
  clone_url = "http://your.gitlab.server"
```

---

## 4. 테스트 파이프라인 구성

### `.gitlab-ci.yml`

```yaml
stages:
  - build
  - test

build-job:
  stage: build
  script:
    - echo "Build step"
  tags:
    - group_tag

test-job:
  stage: test
  script:
    - echo "Test step"
  tags:
    - group_tag
```

---

## 5. 실행 결과 및 확인

- GitLab UI 상에서 Runner 상태: `Online`, `Idle`
- Job 실행 시 로그:

  - Docker Executor가 `alpine:latest` 이미지로 컨테이너 실행
  - `git fetch` 시 인증 실패 → `clone_url` 설정 추가 후 정상 작동
  - `echo` 명령 실행 완료 후 Job 성공

---

## ✅ 결론

- 그룹 단위 Runner 등록 시, 토큰은 그룹 설정에서 확인 가능
- Runner 컨테이너에서는 `gitlab-runner register`로 등록
- `config.toml`에 `clone_url`을 추가해야 HTTP 인증 문제 해결 가능
- `.gitlab-ci.yml`에 태그(`tags:`)를 명시해야 해당 Runner가 Job을 수신함

위 과정을 통해 GitLab 그룹 단위로 Runner를 성공적으로 구성하고, CI/CD 파이프라인 테스트까지 완료함.
