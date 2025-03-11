# Jenkins vs GitOps 차이점 정리

## 📌 개요

Jenkins와 GitOps는 모두 소프트웨어 개발 및 배포 파이프라인에서 중요한 역할을 하지만, 그 **목적, 방식, 개념**에서 차이를 보입니다. 이 문서는 Jenkins와 GitOps의 차이점과 각각의 역할에 대해 설명합니다.

---

## ✅ Jenkins란?

- Jenkins는 **CI/CD 자동화 도구**입니다.
- 개발자가 코드를 변경하고 Git에 Push하면, Jenkins가 자동으로 **빌드, 테스트, 배포 파이프라인**을 실행합니다.
- 주로 **Push 방식의 배포(직접 서버에 명령 실행)**를 사용합니다.

### Jenkins 주요 특징

- 빌드/테스트/배포 단계 자동화
- Groovy 기반 Jenkinsfile로 파이프라인 정의
- 다양한 플러그인 연동 (Slack, Git, Docker 등)
- 자유도 높은 배포 스크립트 작성 가능

---

## ✅ GitOps란?

- GitOps는 **Git을 단일 진실의 소스(Single Source of Truth)**로 삼아, Git 저장소의 상태를 기준으로 클러스터(운영 환경)를 자동으로 동기화하는 **운영 방식 또는 문화**입니다.
- 배포는 사람이 명령하지 않고, **컨트롤러(ArgoCD, FluxCD 등)가 Git 변경 사항을 감지하여 Pull 방식으로 자동 반영**합니다.

### GitOps 주요 특징

- Git에 선언형(Infrastructure as Code) 설정 파일 저장
- 배포는 Git 변경 → 클러스터 상태 자동 동기화
- 자동 롤백/이력 추적 용이 (Git 커밋 로그 기반)
- 배포와 운영의 투명성과 일관성 향상

---

## 🚀 Git에서 배포하는 방식 (GitOps 방식 자세히 설명)

GitOps에서의 배포는 다음과 같은 방식으로 이루어집니다:

### 1. **Git 저장소 구성**

- 애플리케이션 코드와 별도로 **배포용 저장소**를 구성
- 해당 저장소에는 Kubernetes manifests, Helm charts, Kustomize 등 **선언형 배포 설정 파일**을 포함

### 2. **변경 사항 커밋**

- 새로운 버전을 배포하고 싶다면, `deployment.yaml` 등 manifest 파일의 image tag 또는 설정 값을 수정한 뒤 커밋

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  containers:
    - name: myapp
      image: myregistry/myapp:1.2.3 # <-- 이 부분 변경
```

### 3. **Pull 기반 배포 자동화 (ArgoCD/FluxCD)**

- ArgoCD나 FluxCD는 Git 저장소의 변경 사항을 **주기적으로 감시**하거나 Webhook으로 실시간 감지
- 변경 사항 감지 → 현재 클러스터 상태와 비교 → 자동으로 **동기화(Sync)** 수행

### 4. **자동 롤백/이력 추적**

- 문제가 발생하면 Git에서 이전 커밋으로 롤백하여 **자동 재배포** 가능

### 5. **배포 흐름 예시 (ArgoCD 기준)**

```
Git Commit (배포 설정 변경)
→ ArgoCD가 변경 감지
→ 클러스터에 자동 적용
→ 상태 모니터링 및 자동 복구
```

---

## 🔍 비교 정리

| 항목      | Jenkins                 | GitOps                      |
| --------- | ----------------------- | --------------------------- |
| 정의      | CI/CD 자동화 도구       | Git 기반 배포 및 운영 모델  |
| 기반 개념 | 파이프라인 중심         | 선언형 인프라 중심          |
| 배포 방식 | Push 방식 (명령 수행)   | Pull 방식 (Git 상태 감지)   |
| 주 대상   | Build/Test/Deploy 전체  | Deploy/운영 상태 유지 중심  |
| 도구 예시 | Jenkins, GitLab CI 등   | ArgoCD, FluxCD 등           |
| 장점      | 유연한 작업 처리        | 운영 일관성, 자동 복구 가능 |
| 단점      | 운영 상태 불일치 가능성 | 초기 셋업 학습 곡선 있음    |

---

## 🧪 실제 예시 흐름

### Jenkins 방식

```
개발자 → Git Push → Jenkins 파이프라인 실행 → 서버 배포 스크립트 실행
```

### GitOps 방식

```
개발자 → Git Push (배포 YAML 수정) → ArgoCD가 Git 변경 감지 → 자동 배포 적용
```

---

## 💡 함께 사용하는 구조 예시

- Jenkins는 **Build + Test (CI)** 역할 수행
- GitOps는 **Deploy (CD)** 역할 수행

### 예시 흐름:

```
Jenkins: 코드 빌드 및 테스트
→ 빌드 산출물 또는 배포 Manifest를 Git에 커밋
→ GitOps(ArgoCD 등): 변경 감지 후 자동 배포
```

---

## ✅ 결론

| Jenkins                      | GitOps                    |
| ---------------------------- | ------------------------- |
| CI/CD 도구 (파이프라인 기반) | Git 중심의 CD 운영 방법론 |

둘은 배타적인 개념이 아니며, **CI는 Jenkins, CD는 GitOps**로 결합하여 **효율적이고 안정적인 배포 자동화**를 구축할 수 있습니다.
