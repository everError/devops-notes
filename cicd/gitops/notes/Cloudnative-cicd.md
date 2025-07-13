## ☁️ 클라우드 네이티브 CI/CD 개요

클라우드 네이티브 CI/CD는 **클라우드 환경에 최적화된 방식으로 지속적 통합(CI)과 지속적 배포(CD)를 구현**하는 전략입니다.

---

### 📌 클라우드 네이티브란?

* **컨테이너**, **마이크로서비스**, **동적 오케스트레이션**, **불변 인프라** 등의 특성을 가진 현대적 애플리케이션 아키텍처
* 대표 기술: Docker, Kubernetes, Service Mesh, Serverless 등

---

### 🔁 CI/CD 기본 개념

| 용어                                  | 설명                                   |
| ----------------------------------- | ------------------------------------ |
| CI (Continuous Integration)         | 코드 변경 사항을 지속적으로 통합하고 자동 테스트하는 프로세스   |
| CD (Continuous Delivery/Deployment) | 통합된 코드를 자동으로 배포 환경까지 전달 및 릴리즈하는 프로세스 |

---

### ⚙️ 클라우드 네이티브 CI/CD 특징

1. **컨테이너 기반 빌드 및 배포**

   * 모든 애플리케이션 빌드 아티팩트를 Docker 이미지로 패키징
   * 환경 차이에 따른 오류 최소화

2. **Kubernetes 기반 배포 자동화**

   * `kubectl`, `helm`, `kustomize` 등을 통한 배포
   * Argo CD, Flux 등 GitOps 도구 활용 가능

3. **GitOps 방식의 운영**

   * Git을 단일 소스 오브 트루스로 활용
   * Git에 커밋 시 자동으로 클러스터에 반영됨 (Argo CD, Flux 등)

4. **분산형 파이프라인 구성**

   * Jenkins X, Tekton, Argo Workflows 등 클라우드 네이티브 CI 도구 사용
   * 각 작업이 컨테이너로 실행되어 수평 확장 용이

5. **인프라 자동화 및 IaC 통합**

   * Terraform, Pulumi 등과 통합해 인프라까지 포함한 전체 프로비저닝 가능

6. **Observability 및 Rollback 전략 내장**

   * Prometheus, Grafana, Loki, Jaeger 등의 도구로 모니터링 및 트레이싱 구성
   * Canary/Blue-Green 배포 전략 자동화

---

### 🛠️ 주요 도구

| 영역        | 도구 예시                                         |
| --------- | --------------------------------------------- |
| CI 서버     | GitHub Actions, GitLab CI, Jenkins X, Tekton  |
| CD 도구     | Argo CD, Flux, Spinnaker                      |
| IaC       | Terraform, Pulumi, Crossplane                 |
| 이미지 레지스트리 | Docker Hub, GitHub Container Registry, Harbor |
| 배포 도구     | Helm, Kustomize, kubectl                      |
| 모니터링      | Prometheus, Grafana, Loki                     |

---

### 📈 배포 전략

* **Rolling Update**: 점진적으로 Pod 교체
* **Canary Release**: 소수 트래픽에만 배포 후 점진 확장
* **Blue-Green Deployment**: 전체 새 환경 준비 후 트래픽 스위칭

---

### ✅ 베스트 프랙티스

1. 모든 인프라/앱 설정은 Git으로 관리
2. 변경은 Pull Request로 관리하고 리뷰 필수
3. 파이프라인은 선언형 구성으로 문서화
4. 실패 시 자동 롤백 및 알림 시스템 구축
5. 테스트, 보안, 린트 자동화 포함
6. 멀티 클러스터/멀티 테넌시 고려한 구성

---

### 🧭 결론

클라우드 네이티브 CI/CD는 기존 CI/CD를 넘어서 **컨테이너 중심, Git 중심, 오케스트레이션 중심의 운영 방식**으로 발전한 모델입니다. DevOps와 GitOps 문화에 기반해 **개발-테스트-배포-운영의 자동화와 일관성**을 극대화할 수 있습니다.
