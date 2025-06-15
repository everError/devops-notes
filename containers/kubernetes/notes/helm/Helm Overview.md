## 🧠 Helm이란?

**Helm**은 Kubernetes 환경에서 애플리케이션을 손쉽게 배포하고 관리하기 위한 **패키지 매니저**이다. 복잡한 Kubernetes 리소스(YAML 파일)를 효율적으로 템플릿화하고 설정 파일로 관리할 수 있도록 도와준다.

---

### 🎁 Helm의 주요 역할

Helm은 다음과 같은 기능을 수행한다:

- 여러 Kubernetes 리소스를 하나의 패키지(Chart)로 묶는다.
- values.yaml을 통해 설정값만 바꿔서 재사용 가능하게 한다.
- 템플릿 시스템으로 복잡한 YAML 구성을 단순화한다.
- 설치, 업그레이드, 롤백 등을 명령어로 간단히 수행할 수 있다.

---

### 📦 Helm Chart란?

Helm Chart는 Helm에서 사용하는 **애플리케이션 패키지**로, Kubernetes 애플리케이션을 정의하는 YAML 템플릿들의 모음이다.

#### Chart 구성 요소

- `Chart.yaml`: Chart의 이름, 버전 등의 메타정보
- `values.yaml`: 사용자 설정값 (변경 가능한 부분)
- `templates/`: Deployment, Service 등 실제 리소스 템플릿
- `charts/`: 의존성 Chart 디렉토리

---

### 🧩 Helm의 핵심 기능 요약

| 기능      | 설명                                            |
| --------- | ----------------------------------------------- |
| 패키징    | 여러 YAML 파일을 하나의 Chart로 구성            |
| 설정 분리 | 설정값을 values.yaml로 분리하여 재사용성 향상   |
| 템플릿화  | Go 템플릿 문법으로 YAML 생성 자동화             |
| 버전 관리 | 업그레이드 및 롤백 지원                         |
| 저장소    | Chart Repository를 통해 Chart 공유 및 배포 가능 |

---

### 🔄 Helm 사용의 장점

- **환경별 배포 분리** (dev/stage/prod 등): values.yaml만 바꿔서 운영 가능
- **명령어 기반 배포**: `helm install`, `helm upgrade`, `helm rollback` 등
- **표준화**: Helm Chart를 통해 배포 프로세스를 템플릿화하고 일관성 유지
- **빠른 도입**: 인기 오픈소스 nginx, prometheus 등의 Chart가 공식 저장소에 존재

---

### 🎯 Helm vs kubectl

| 항목        | kubectl apply  | Helm                           |
| ----------- | -------------- | ------------------------------ |
| 유지보수    | 수동 YAML 수정 | values.yaml 수정으로 간편 관리 |
| 재사용성    | 낮음           | 높음 (템플릿 기반)             |
| 롤백        | 수동 관리      | `helm rollback` 명령어 지원    |
| 의존성 관리 | 직접 구성      | Chart 간 의존성 정의 가능      |
