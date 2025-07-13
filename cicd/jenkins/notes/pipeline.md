# Jenkins 배포 파이프라인이란?

## 📌 개요

Jenkins에서의 배포 파이프라인은 **소프트웨어를 자동으로 빌드하고 테스트한 후, 운영 환경 또는 다른 대상 환경에 배포하는 일련의 자동화된 과정**을 의미합니다. 수동 배포의 오류와 반복 작업을 줄이고, 빠르고 안정적인 배포를 가능하게 합니다.

---

## 🏗️ Jenkins 배포 파이프라인의 구성

Jenkins 배포 파이프라인은 일반적으로 다음과 같은 단계로 구성됩니다:

1. **코드 가져오기 (Checkout)**

   - GitHub, GitLab 등에서 소스 코드를 가져옵니다.
   - `git clone`, `checkout scm` 등의 명령을 사용합니다.

2. **환경 설정 (Set Environment)**

   - `.env` 파일 또는 Jenkins 환경 변수로 실행 환경을 설정합니다.
   - Jenkins 시스템 내에 Global Environment Variable을 설정하거나 `environment` 블록을 사용합니다.

3. **빌드(Build)**

   - 소스 코드를 실행 가능한 애플리케이션으로 컴파일하거나 패키징합니다.
   - 예시 명령어:
     - `.NET`: `dotnet publish -c Release -o ./publish`
     - `Node.js`: `npm run build`
     - `Vue/React`: `yarn install && yarn build`

4. **테스트(Test)**

   - 유닛 테스트, 통합 테스트 등 자동화된 테스트를 실행합니다.
   - 테스트 도구 예시: `xUnit`, `Jest`, `Mocha`, `NUnit` 등
   - Jenkins에서는 `JUnit` 플러그인을 사용해 테스트 결과를 시각화할 수 있습니다.

5. **배포(Deploy)**

   - 빌드된 결과물을 서버에 복사하거나, Docker 이미지를 빌드하여 컨테이너로 실행합니다.
   - 배포 방식:
     - `rsync`, `scp`, `ftp`를 통한 파일 복사
     - `docker build`, `docker run`, `docker-compose up` 등
     - 서버에서 서비스 재시작: `systemctl restart nginx`

6. **알림(Notify)**
   - 배포 결과를 Slack, 이메일, Mattermost 등으로 알림 전송
   - Jenkins 플러그인: `Slack Notification`, `Email Extension Plugin`

---

## ✍️ Jenkinsfile 작성법

Jenkins에서는 **Jenkinsfile**을 통해 파이프라인을 코드로 작성합니다. 대표적으로 Declarative Pipeline 문법을 사용합니다.

### 예시 Jenkinsfile (Declarative Pipeline)

```groovy
pipeline {
  agent any

  environment {
    NODE_ENV = 'production'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Install & Build') {
      steps {
        sh 'yarn install'
        sh 'yarn build'
      }
    }

    stage('Test') {
      steps {
        sh 'yarn test'
      }
    }

    stage('Deploy') {
      steps {
        sh 'rsync -av ./dist/ user@server:/var/www/project/'
        sh 'ssh user@server "systemctl restart nginx"'
      }
    }
  }

  post {
    success {
      echo '✅ 배포 성공'
    }
    failure {
      echo '❌ 배포 실패'
    }
  }
}
```

---

## 💡 왜 Jenkins 배포 파이프라인이 중요한가?

- **자동화**: 반복적인 수동 작업을 줄이고 일관된 배포 품질을 유지
- **빠른 피드백**: 코드 변경 직후 테스트 및 배포를 통해 빠른 오류 발견
- **신뢰성**: 정형화된 프로세스로 배포 오류 최소화
- **유지보수 용이성**: 문서화된 파이프라인으로 팀원 간 협업 효율 증대

---

## 📎 참고 사항

- Jenkins는 Declarative Pipeline (`Jenkinsfile`)을 통해 코드를 기반으로 파이프라인을 정의할 수 있습니다.
- GitLab, GitHub, Bitbucket 등의 **Webhook**과 연동하여 자동으로 파이프라인을 시작할 수 있습니다.
- Docker, Kubernetes, Ansible 등과 함께 사용하여 고도화된 배포 시스템을 구축할 수 있습니다.

---

## ✅ 결론

Jenkins 배포 파이프라인은 **CI/CD(지속적 통합/지속적 배포)** 구현의 핵심 요소로, 개발과 운영 사이의 경계를 줄이고 더 빠르고 안정적인 서비스를 제공하기 위한 핵심 도구입니다.
