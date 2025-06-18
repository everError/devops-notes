# GitLab CI/CD를 이용한 Docker 기반 자동 빌드 및 배포 원리 및 구성

## 1. 전체 작동 원리 (동작 흐름)

GitLab CI/CD는 GitLab 저장소에 커밋 등의 이벤트가 발생했을 때, `.gitlab-ci.yml`에 정의된 대로 CI/CD 파이프라인을 자동으로 실행합니다. 이 파이프라인은 GitLab Runner를 통해 실제 작업을 수행하며, Docker 이미지를 빌드하고 레지스트리에 푸시한 뒤, 원격 서버에 배포할 수 있습니다.

```
[1] GitLab 저장소에 push
     ↓
[2] GitLab이 `.gitlab-ci.yml` 파일을 읽고 파이프라인 생성
     ↓
[3] GitLab Runner에게 Job 할당
     ↓
[4] Runner가 Docker build/push/deploy 수행
     ↓
[5] 결과가 GitLab UI에 표시됨
```

---

## 2. 배포 환경 구성 시 필요한 요소 및 예시 개념 설명

자동 빌드 및 배포 환경을 구성하기 위해서는 다음과 같은 구성 요소들이 필요합니다. 각각의 개념과 예시를 아래에 설명합니다.

### 2.1 GitLab 저장소

* 애플리케이션 소스 코드가 저장되는 GitLab 프로젝트입니다.
* `.gitlab-ci.yml` 파일을 루트에 포함시켜 파이프라인 정의
* 예: `https://gitlab.example.com/group/project`

### 2.2 GitLab CI/CD Pipeline 정의 (`.gitlab-ci.yml`)

* 파이프라인의 실행 단계를 정의하는 YAML 파일
* 예시:

```yaml
stages:
  - build
  - deploy

build:
  stage: build
  script:
    - docker build -t myapp:latest .
```

### 2.3 GitLab Runner

* GitLab에서 정의된 Job을 실제로 실행하는 에이전트
* Docker executor를 사용하는 경우, Runner 자체가 Docker 안에서 docker 명령을 실행해야 하므로 `docker-in-docker(dind)` 설정 필요
* 설치 예시:

```bash
docker run -d --name gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest
```

### 2.4 Docker 및 Dockerfile

* 애플리케이션을 컨테이너화하기 위한 설정 파일 (`Dockerfile`)
* Docker CLI를 통해 이미지 빌드 및 실행 가능
* 예시 Dockerfile:

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY . .
RUN npm install
CMD ["npm", "start"]
```

### 2.5 Docker Registry

* 빌드된 Docker 이미지를 저장할 중앙 저장소
* GitLab Container Registry, Docker Hub, AWS ECR, Harbor 등 사용 가능
* 예시 이미지 경로: `registry.gitlab.example.com/mygroup/myapp:latest`

### 2.6 원격 배포 서버 (Deploy Server)

* 실제 애플리케이션을 실행할 서버
* SSH 접근이 가능해야 하며 Docker가 설치되어 있어야 함
* GitLab Runner가 이 서버에 접속하여 `docker pull`, `docker run` 등의 명령어 실행

### 2.7 CI/CD 환경 변수 설정

* GitLab 프로젝트의 Settings > CI/CD > Variables 메뉴에서 설정
* 민감한 정보 (예: 레지스트리 로그인, SSH 비밀번호 등)는 여기에서 안전하게 관리

| 변수명                    | 설명                     |
| ---------------------- | ---------------------- |
| `CI_REGISTRY`          | Docker 레지스트리 주소        |
| `CI_REGISTRY_USER`     | 레지스트리 사용자명             |
| `CI_REGISTRY_PASSWORD` | 레지스트리 비밀번호 또는 토큰       |
| `DEPLOY_USER`          | 원격 서버 SSH 접속 ID        |
| `DEPLOY_HOST`          | 배포 대상 서버 주소(IP 또는 도메인) |

---

## 3. 작동 조건 및 설정 순서

1. GitLab 프로젝트에 `.gitlab-ci.yml` 작성 및 커밋
2. GitLab Runner 등록 및 실행
3. CI/CD 환경변수 등록
4. Dockerfile 작성 및 서비스별 구성
5. 배포 대상 서버 구성 (SSH 접속 가능, Docker 설치 필수)
6. 필요시 Registry 인증 구성 및 접근 허용

---

## 4. 실행 조건 제어 (브랜치 기준 등)

`.gitlab-ci.yml` 내에서 브랜치 조건으로 특정 Job이 실행될지 여부를 제어할 수 있습니다.

```yaml
rules:
  - if: '$CI_COMMIT_BRANCH == "main"'
    when: always
  - when: never
```

---

## 5. 추가 고급 구성

* `only/except`, `rules`를 활용한 Job 분기 처리
* 변경 파일 경로 기반 selective build (`git diff` 활용)
* 다중 서비스 (MSA) 빌드를 위한 job 매트릭스 구성
* 실패 시 알림 연동 (Slack, Discord, Webhook 등)

---

## ✅ 결론

GitLab CI/CD는 `.gitlab-ci.yml` 파일을 통해 전체 빌드/배포 과정을 자동화할 수 있는 매우 유연한 도구입니다. 핵심은 Git 이벤트 → 파이프라인 트리거 → Runner가 작업 실행이라는 흐름이며, 이 과정을 이해하고 필요한 구성요소를 갖추면 자동화를 실현할 수 있습니다.
