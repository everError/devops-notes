# 🚢 Shipwright: Kubernetes 네이티브 컨테이너 이미지 빌드 프레임워크

## ✅ 개요

**Shipwright**는 Kubernetes 네이티브 방식으로 컨테이너 이미지를 빌드할 수 있는 프레임워크입니다. Docker와 같은 데몬 기반 도구 없이도, Kubernetes 클러스터 내부에서 안전하게 이미지를 빌드할 수 있도록 설계되었습니다.

Shipwright는 다양한 빌드 도구(Kaniko, Buildah, Buildpacks 등)를 **빌드 전략(BuildStrategy)** 으로 추상화하여, 빌드 정의(`Build`)와 실행(`BuildRun`)을 통해 이미지를 생성합니다.

---

## 🧩 주요 구성 요소

| 리소스                                   | 역할                                                          |
| ---------------------------------------- | ------------------------------------------------------------- |
| **BuildStrategy / ClusterBuildStrategy** | Kaniko, Buildah, Buildpacks 등 어떤 빌드 도구를 사용할지 명시 |
| **Build**                                | 어떤 소스를 어떤 방식으로 어떤 이미지로 빌드할지 정의         |
| **BuildRun**                             | 실제 빌드를 실행하는 트리거 역할                              |

---

## ⚙️ 작동 방식

```plaintext
[사용자] → Build CR 작성
        → BuildRun 생성
                ↓
     [Shipwright Controller]
        → BuildStrategy에 따라 Job 생성
                ↓
     [Kubernetes 내부에서 빌드 실행]
        → 컨테이너 이미지 빌드 후 레지스트리에 push
```

- Shipwright는 빌드 도구를 직접 내장하지 않고, **빌드 전략으로 정의된 외부 빌더**를 Kubernetes Job으로 실행
- 데몬리스 환경(예: Buildah, Kaniko)을 활용해 보안성 높음

---

## 🛠️ 예시 YAML

### 🔹 Build 리소스 예시

```yaml
apiVersion: shipwright.io/v1alpha1
kind: Build
metadata:
  name: my-app
spec:
  source:
    url: https://github.com/my-org/my-app
  strategy:
    name: buildah
    kind: ClusterBuildStrategy
  output:
    image: ghcr.io/my-org/my-app:latest
```

### 🔹 BuildRun 실행

```yaml
apiVersion: shipwright.io/v1alpha1
kind: BuildRun
metadata:
  name: my-app-run
spec:
  buildRef:
    name: my-app
```

---

## ✅ 장점

- ✅ Kubernetes CRD 기반으로 선언적 빌드 정의 가능
- ✅ Docker 데몬 없이도 빌드 수행 가능 (보안성 향상)
- ✅ 다양한 빌드 도구와 호환 (Kaniko, Buildah, Buildpacks, Spectrum 등)
- ✅ GitOps 및 Tekton 기반 워크플로와 연동 쉬움

---

## ❗ 비교: Shipwright vs Skaffold vs Tekton

| 항목             | Shipwright           | Skaffold              | Tekton                      |
| ---------------- | -------------------- | --------------------- | --------------------------- |
| 목적             | 이미지 빌드 전용     | 개발-배포 반복 자동화 | CI/CD 전체 파이프라인 구축  |
| 빌드 실행 위치   | Kubernetes 내부      | 로컬 또는 CI 서버     | Kubernetes 내부 (Task 기반) |
| CRD 사용         | ✅ Build, BuildRun   | ❌                    | ✅ Pipeline, Task 등        |
| 빌드 전략 확장성 | 매우 높음 (플러그블) | 낮음                  | 중간 (Task 정의 필요)       |
| Docker 필요 여부 | ❌                   | 보통 필요             | ❌                          |

---

## 📦 Shipwright 지원 빌더 예시

- **Buildah**
- **Kaniko**
- **Cloud Native Buildpacks**
- **Spectrum**

각 빌더는 `ClusterBuildStrategy`로 설정하여 사용할 수 있음.

---

## 🔗 참고 자료

- GitHub: [https://github.com/shipwright-io/build](https://github.com/shipwright-io/build)
- 공식 문서: [https://shipwright.io/docs/](https://shipwright.io/docs/)
- Build Strategy 예제: [https://github.com/shipwright-io/sample-strategies](https://github.com/shipwright-io/sample-strategies)

---

## ✅ 요약

> Shipwright는 Kubernetes 환경에서 다양한 빌더를 활용해 컨테이너 이미지를 안전하고 유연하게 빌드할 수 있게 해주는 **데몬리스 빌드 프레임워크**입니다.
