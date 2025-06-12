# 📘 Kubernetes YAML 기초 문법: Namespace, Deployment, Service

Kubernetes에서는 모든 리소스를 선언형(Declarative) 방식으로 정의할 수 있으며, 그 중심에 있는 것이 YAML 파일입니다. 아래는 기본적으로 많이 사용하는 리소스인 **Namespace**, **Deployment**, **Service**에 대한 YAML 작성 예시와 구조 설명입니다.

---

## ✨ YAML 구성 개념 요약

YAML 파일에서 Kubernetes 리소스를 정의할 때 주요 개념은 다음과 같습니다:

### 🔹 `apiVersion`

- 리소스가 속한 Kubernetes API 그룹과 그 버전을 지정합니다.
- 올바른 `apiVersion`은 리소스마다 다릅니다. 예:

  - `apps/v1` → Deployment, StatefulSet, DaemonSet 등
  - `batch/v1` → Job, CronJob
  - `v1` → Pod, Service, ConfigMap, Namespace 등 (core 그룹)

- 구버전에서는 `extensions/v1beta1` 등이 사용되었지만, 현재는 대부분 제거되었습니다.

### 🔹 `kind`

- 정의하려는 리소스의 타입을 지정합니다.
- 예시: `Deployment`, `Service`, `Pod`, `ConfigMap`, `Ingress`, `Secret` 등

### 🔹 `metadata`

- 리소스에 대한 식별 정보(메타데이터)를 담습니다.

  - `name`: 리소스 이름 (필수)
  - `namespace`: 네임스페이스 (지정하지 않으면 `default` 사용)
  - `labels`, `annotations`: 선택적 메타데이터로 리소스 필터링이나 정보 전달에 사용
  - 라벨은 주로 리소스를 그룹화하거나 선택자로 사용되며, 다음과 같은 구조화된 표준 라벨이 자주 사용됩니다:

    ```yaml
    metadata:
      name: example
      labels:
        app.kubernetes.io/name: my-app
        app.kubernetes.io/instance: my-app-001
        app.kubernetes.io/version: "1.0.0"
        app.kubernetes.io/component: backend
        app.kubernetes.io/part-of: ecommerce-platform
        app.kubernetes.io/managed-by: helm
    ```

    | 라벨 키                        | 설명                                                      |
    | ------------------------------ | --------------------------------------------------------- |
    | `app.kubernetes.io/name`       | 애플리케이션 이름 (고유 식별자)                           |
    | `app.kubernetes.io/instance`   | 동일한 앱의 인스턴스 이름 (예: helm release)              |
    | `app.kubernetes.io/version`    | 앱의 버전 (예: `"1.0.0"`)                                 |
    | `app.kubernetes.io/component`  | 구성 요소 (예: frontend, backend, database)               |
    | `app.kubernetes.io/part-of`    | 상위 시스템 또는 플랫폼 이름                              |
    | `app.kubernetes.io/managed-by` | 리소스를 생성한 도구 또는 관리자 (예: helm, kustomize 등) |

    이러한 표준 라벨은 Helm, ArgoCD, Kustomize 같은 툴에서 리소스를 추적하거나 관리하는 데 사용됩니다.

### 🔹 `spec`

- 리소스의 실제 스펙(동작 방식)을 정의합니다.
- 어떤 컨테이너를 쓸지, 몇 개의 복제본을 유지할지, 어떤 볼륨을 사용할지 등을 설정합니다.
- 리소스의 종류에 따라 구조가 완전히 달라집니다 (예: Deployment의 `spec` vs Service의 `spec`)

  - `Deployment.spec` 주요 필드:

    | 필드                       | 설명                            |
    | -------------------------- | ------------------------------- |
    | `replicas`                 | 생성할 Pod의 수                 |
    | `selector`                 | 어떤 Pod를 관리할지 선택자 정의 |
    | `template`                 | 생성할 Pod의 정의               |
    | `template.metadata.labels` | Pod에 부여될 라벨 정의          |
    | `template.spec.containers` | 컨테이너 목록 및 속성 정의      |

  - `Service.spec` 주요 필드:

    | 필드               | 설명                                               |
    | ------------------ | -------------------------------------------------- |
    | `selector`         | 연결할 Pod의 라벨 선택자                           |
    | `ports.port`       | 외부로 노출될 포트                                 |
    | `ports.targetPort` | 연결할 Pod 내부 포트                               |
    | `type`             | Service 종류: ClusterIP, NodePort, LoadBalancer 등 |

  - `Namespace.spec`는 일반적으로 사용되지 않으며, 대부분 `metadata`만 정의함.

> 이 4개 (`apiVersion`, `kind`, `metadata`, `spec`)는 거의 모든 리소스에서 기본 뼈대가 됩니다.

---

## 📁 1. Namespace

### ✅ 목적

- Kubernetes 리소스를 격리하는 논리적 공간

### 📝 예시

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: my-namespace
```

### 📌 설명

| 필드            | 설명                     |
| --------------- | ------------------------ |
| `apiVersion`    | core API 그룹은 `v1`     |
| `kind`          | 리소스 종류: Namespace   |
| `metadata.name` | 생성할 네임스페이스 이름 |

---

## 📁 2. Deployment

### ✅ 목적

- Pod를 정의하고, 지정된 수만큼 유지하는 컨트롤러
- 이미지 롤링 업데이트, 복구, 스케일링 지원

### 📝 예시

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: my-namespace
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: app-container
          image: nginx:latest
          ports:
            - containerPort: 80
```

### 📌 설명

| 필드                       | 설명                                 |
| -------------------------- | ------------------------------------ |
| `replicas`                 | 실행할 Pod 수                        |
| `selector.matchLabels`     | 어떤 Pod가 대상인지 정의 (필수)      |
| `template.metadata.labels` | Pod에 적용할 라벨 (Service와 연동됨) |
| `containers.image`         | 사용할 컨테이너 이미지               |
| `ports.containerPort`      | 컨테이너 내부 포트                   |

---

## 📁 3. Service

### ✅ 목적

- Pod 집합에 접근 가능한 **네트워크 엔드포인트** 생성
- ClusterIP, NodePort, LoadBalancer 등 다양한 방식 제공

### 📝 예시

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: my-namespace
spec:
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: NodePort
```

### 📌 설명

| 필드               | 설명                                                  |
| ------------------ | ----------------------------------------------------- |
| `selector`         | 어떤 Pod의 라벨을 선택할지 (Deployment와 연동됨)      |
| `ports.port`       | 서비스가 외부에 노출하는 포트                         |
| `ports.targetPort` | Pod의 컨테이너가 사용하는 실제 포트                   |
| `type`             | 서비스 종류 (`ClusterIP`, `NodePort`, `LoadBalancer`) |

---

## ✅ 종합 적용 예시 (순서)

```bash
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

모든 리소스가 같은 `namespace`에 지정되어 있어야 함.
