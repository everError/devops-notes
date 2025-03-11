# Jenkins + GitOps 기반 배포 파이프라인 정리

## 📌 개요

이 문서는 **Jenkins와 GitOps(ArgoCD 등)**를 연계하여 소프트웨어를 자동으로 **이미지 빌드 → 이미지 Push → 배포**까지 수행하는 전체 흐름을 정리한 문서입니다.

---

## ✅ 전체 배포 흐름 요약

```
1. 개발자가 애플리케이션 소스코드를 Git에 Push
2. Jenkins가 트리거되어 다음 작업 수행:
   - Docker 이미지 Build
   - Docker Hub에 이미지 Push
   - GitOps 배포 레포지토리의 manifest 파일(deployment.yaml 등) 수정 및 커밋
3. ArgoCD(또는 FluxCD)가 GitOps 레포지토리 변경을 감지하여 클러스터에 자동 배포
```

---

## ⚙️ 단계별 설명

### 1️⃣ 개발자 Git Push

- 코드 변경 후 Git에 Push
- Jenkins Webhook 또는 Poll SCM으로 자동 트리거

### 2️⃣ Jenkins CI 파이프라인

- Jenkinsfile 구성 예시:

```groovy
pipeline {
  agent any
  stages {
    stage('Build Docker Image') {
      steps {
        sh 'docker build -t myapp:1.2.3 .'
      }
    }
    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            docker tag myapp:1.2.3 mydockerhub/myapp:1.2.3
            docker push mydockerhub/myapp:1.2.3
          '''
        }
      }
    }
    stage('Update GitOps Repository') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'gitops-creds', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
          sh '''
            git clone https://${GIT_USER}:${GIT_PASS}@git.example.com/ops/deploy-repo.git
            cd deploy-repo
            sed -i 's/myapp:.*/myapp:1.2.3/' k8s/deployment.yaml
            git config user.name "CI Bot"
            git config user.email "ci@example.com"
            git commit -am "Update myapp image tag to 1.2.3"
            git push origin main
          '''
        }
      }
    }
  }
}
```

### 3️⃣ GitOps 컨트롤러 (ArgoCD 등)

- ArgoCD가 배포용 GitOps 레포지토리 상태를 주기적으로 또는 실시간으로 감시
- 변경된 manifest (예: `deployment.yaml`)를 감지
- 클러스터 상태와 Git 상태를 비교하여 자동 배포(Sync)

---

## 📂 예시 GitOps 배포 manifest (deployment.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: myapp
          image: mydockerhub/myapp:1.2.3 # ← Jenkins가 자동으로 변경
          ports:
            - containerPort: 3000
```

---

## ✅ 결론 및 요약

- **Jenkins는 CI(이미지 빌드, 테스트, Push) 역할**
- **GitOps는 CD(배포 자동화, 클러스터 상태 동기화) 역할**
- 두 방식은 상호 보완적으로 함께 사용되며, 안정적이고 반복 가능한 자동화 배포 환경을 구성할 수 있습니다.
