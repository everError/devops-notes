# GitLab CI 문법 정리

GitLab CI/CD에서는 `.gitlab-ci.yml` 파일로 파이프라인을 정의하며, 주요 구성 요소와 문법은 다음과 같습니다.

---

## 1. 기본 구조

```yaml
stages:
  - build
  - test
  - deploy

job_name:
  stage: build
  script:
    - echo "작업 내용"
```

---

## 2. 주요 키워드

### ✅ `stages`

- 파이프라인 단계 정의

```yaml
stages:
  - build
  - deploy
```

### ✅ `script`

- 실제 실행되는 쉘 명령어 리스트

```yaml
script:
  - npm install
  - npm run build
```

### ✅ `tags`

- 특정 Runner에서만 Job 실행 (Runner 등록 시 지정한 태그와 매칭)

```yaml
tags:
  - docker
```

### ✅ `only` / `except` _(deprecated)_

- 특정 브랜치에서만 실행

```yaml
only:
  - main
  - dev
```

> **주의:** `only/except`는 `rules`로 대체되는 추세

### ✅ `rules`

- 보다 유연한 조건 설정 가능

```yaml
rules:
  - if: '$CI_COMMIT_BRANCH == "main"'
    when: manual
  - if: '$CI_COMMIT_BRANCH == "dev"'
    when: on_success
  - when: never
```

### ✅ `when`

- Job 실행 시점 제어

  - `on_success` (기본값): 이전 Job 성공 시 실행
  - `manual`: 수동 실행
  - `always`: 항상 실행
  - `never`: 실행 안 함

### ✅ `needs`

- Job 간 의존성 설정 (병렬 실행 최적화)

```yaml
deploy:
  stage: deploy
  needs: [build]
```

### ✅ `artifacts`

- Job 결과물을 다른 Job에서 재사용 가능하게 저장

```yaml
artifacts:
  paths:
    - dist/
  expire_in: 1 hour
```

### ✅ `cache`

- 캐시를 사용해 속도 개선 (의존성 등)

```yaml
cache:
  paths:
    - node_modules/
```

### ✅ `variables`

- 환경 변수 지정

```yaml
variables:
  NODE_ENV: production
```

---

## 3. Job 이름 예시

```yaml
build_app:
  stage: build
  script:
    - echo "Build"
```

---

## 4. 파이프라인 수동 실행 조건

```yaml
rules:
  - if: '$CI_COMMIT_BRANCH == "main"'
    when: manual
```

---

## 5. 기타 유용한 변수

- `$CI_COMMIT_BRANCH`: 현재 브랜치 이름
- `$CI_PIPELINE_SOURCE`: 파이프라인 트리거 방식 (`push`, `web`, `schedule` 등)
- `$CI_PROJECT_DIR`: 체크아웃된 디렉토리
- `$CI_JOB_STAGE`: 현재 Job의 stage 이름

---

## 참고

- 공식 문서: [https://docs.gitlab.com/ee/ci/yaml/](https://docs.gitlab.com/ee/ci/yaml/)
