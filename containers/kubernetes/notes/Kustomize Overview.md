# 🧩 Kustomize 개요: Kubernetes 리소스 커스터마이징 도구

## ✅ Kustomize란?

**Kustomize**는 Kubernetes 리소스(YAML 파일)를 템플릿 없이 **오버레이(overlays)** 방식으로 커스터마이징할 수 있도록 해주는 CLI 도구이자, `kubectl`에 내장된 기능입니다.

템플릿 엔진(Helm 등)과 달리, Kustomize는 **기존 YAML을 그대로 유지**하며, 이를 조합하거나 수정하는 방식으로 배포 구성을 관리합니다.

---

## 📦 주요 개념

| 개념                                | 설명                                                               |
| ----------------------------------- | ------------------------------------------------------------------ |
| **Base**                            | 공통 리소스 정의 (Deployment, Service 등)                          |
| **Overlay**                         | 환경별(dev, prod 등)로 base를 확장 또는 수정하는 레이어            |
| **kustomization.yaml**              | Kustomize 구성 파일로, 어떤 리소스를 포함하고 어떻게 수정할지 정의 |
| **patches / patchesStrategicMerge** | 특정 리소스를 수정하기 위한 패치 방식 (merge or JSON6902)          |

---

## 📁 디렉토리 구조 예시

```plaintext
my-app/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    ├── dev/
    │   ├── kustomization.yaml
    │   └── patch.yaml
    └── prod/
        ├── kustomization.yaml
        └── patch.yaml
```

---

## 🔧 예시: base/kustomization.yaml

```yaml
resources:
  - deployment.yaml
  - service.yaml
```

### 🔧 예시: overlays/dev/kustomization.yaml

```yaml
resources:
  - ../../base

patchesStrategicMerge:
  - patch.yaml
```

### 🔧 예시: overlays/dev/patch.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 2
```

---

## 🚀 적용 명령어

```bash
# 디렉토리 기준으로 커스터마이즈된 YAML 출력
kubectl kustomize overlays/dev

# 실제 클러스터에 적용
kubectl apply -k overlays/dev
```

---

## ✅ Kustomize의 장점

- ✅ 템플릿 엔진 없이도 선언적 구성 가능 (YAML 그대로 유지)
- ✅ 환경별 커스터마이징(dev, staging, prod 등)이 쉬움
- ✅ GitOps와 매우 잘 어울림 (폴더 기반 구성)
- ✅ `kubectl`에 내장되어 별도 설치 없이 사용 가능

---

## 🔗 참고 링크

- 공식 문서: [https://kubectl.docs.kubernetes.io/references/kustomize/](https://kubectl.docs.kubernetes.io/references/kustomize/)
- GitHub: [https://github.com/kubernetes-sigs/kustomize](https://github.com/kubernetes-sigs/kustomize)

---

## 📝 요약

> Kustomize는 Kubernetes 리소스를 **템플릿 없이 커스터마이징**할 수 있도록 해주는 도구로, base + overlay 구조를 통해 환경별 배포 구성을 깔끔하게 관리할 수 있습니다.
