## 🔧 Tekton 개요

Tekton은 **Kubernetes 환경에 최적화된 오픈소스 CI/CD 파이프라인 프레임워크**입니다. Google이 주도하고 CD Foundation에서 관리되며, **컨테이너 기반 파이프라인을 선언형으로 정의**할 수 있게 해줍니다.

---

### 📌 주요 특징

1. **Kubernetes 네이티브**

   * Tekton 리소스는 모두 Kubernetes Custom Resource Definition(CRD) 기반
   * `Pipeline`, `Task`, `PipelineRun`, `TaskRun` 등의 객체로 파이프라인 구성

2. **컨테이너 중심 작업 처리**

   * 각 Task는 컨테이너로 실행
   * 도커 이미지 빌드, 테스트, 린트, 배포 등을 분리된 Task로 구성 가능

3. **재사용 가능한 Task와 Step**

   * 범용 Task들을 미리 정의해 재활용 가능 (ex: git-clone, kaniko build 등)
   * 각 Task 내부는 여러 Step(컨테이너)으로 구성

4. **유연한 파이프라인 흐름 제어**

   * Task 간 의존성 명시 가능 (parallel / sequential execution)
   * 조건문, 매개변수, 워크스페이스 지원

5. **GitOps 및 ArgoCD와 연동 용이**

   * Git에 Push되면 Tekton Pipeline이 자동 실행되는 구조 구현 가능
   * ArgoCD 등과 연동해 GitOps 파이프라인 구성

---

### 🧱 핵심 구성 요소

| 구성 요소                      | 설명                               |
| -------------------------- | -------------------------------- |
| `Task`                     | 하나 이상의 Step으로 구성된 단일 작업 단위       |
| `Pipeline`                 | 여러 Task를 조합한 전체 CI/CD 흐름         |
| `PipelineRun`              | 특정 파이프라인 실행 인스턴스                 |
| `TaskRun`                  | 특정 Task 실행 인스턴스                  |
| `Workspace`                | 공유 스토리지 영역 (PVC 등으로 구현 가능)       |
| `PipelineResource` *(구버전)* | Git, 이미지 등 외부 리소스 (현재는 대체 구조 권장) |

---

### 🛠️ Tekton 생태계

* **Tekton Pipelines**: 핵심 프레임워크
* **Tekton Triggers**: Webhook 기반 이벤트 수신 및 파이프라인 실행
* **Tekton Dashboard**: 웹 기반 UI
* **Tekton CLI (`tkn`)**: 터미널 기반 관리 도구

---

### ✅ 사용 예시 흐름

1. GitHub에 Push 이벤트 발생
2. Tekton Trigger가 이벤트 수신
3. `PipelineRun` 실행 (빌드/테스트/배포 순서)
4. 결과는 Tekton Dashboard 및 로그로 확인

---

### 🔐 보안 및 확장성

* PodSecurityPolicy, RBAC, Secret, ServiceAccount 등 Kubernetes 보안 설정과 연동
* 컨테이너 격리로 안전성 확보
* Tekton Hub를 통해 공개 Task 재사용 가능

---

### 🧭 결론

Tekton은 **클라우드 네이티브 CI/CD를 쿠버네티스 위에 구현하려는 팀에게 이상적인 선택지**입니다. 선언형 구조, 유연한 Task 설계, GitOps 및 Kubernetes 에코시스템과의 깊은 통합으로, **확장성 높고 일관된 자동화 파이프라인**을 구축할 수 있습니다.
