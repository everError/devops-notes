# 무중단 배포 전략 (Zero Downtime Deployment)

서비스를 운영하면서 애플리케이션을 중단 없이 배포하는 다양한 방법을 정리합니다.

---

## 1. Rolling Deployment (롤링 배포)

### 개요

- 기존 인스턴스를 하나씩 교체하며 점진적으로 새로운 버전으로 업데이트하는 방식
- 쿠버네티스의 기본 배포 방식
- 일부 사용자에게만 새 버전이 먼저 배포될 수 있음

### 구현 방법 (Kubernetes)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
```

---

## 2. Blue-Green Deployment (블루-그린 배포)

### 개요

- 기존(Blue)과 새로운(Green) 배포 환경을 동시에 운영하고, 트래픽을 전환
- 빠른 롤백 가능하지만 인프라 비용 증가

### 구현 방법 (Kubernetes)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app-green
```

---

## 3. Canary Deployment (카나리 배포)

### 개요

- 일부 사용자에게 새 버전을 배포한 후 점진적으로 확장하는 방식
- 트래픽 비율을 조절하여 리스크 감소

### 구현 방법 (Kubernetes + Istio)

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-app
spec:
  hosts:
    - my-app.example.com
  http:
    - route:
        - destination:
            host: my-app
            subset: stable
          weight: 90
        - destination:
            host: my-app
            subset: canary
          weight: 10
```

---

## 4. Feature Toggle (기능 플래그)

### 개요

- 배포는 동일하지만, 특정 기능을 활성화/비활성화하여 점진적 배포
- 코드 수정 없이 기능을 컨트롤 가능

### 구현 방법 (Kubernetes ConfigMap)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: feature-flags
data:
  NEW_FEATURE_ENABLED: "true"
```

---

## 5. Shadow Deployment (섀도우 배포)

### 개요

- 실 트래픽을 기존 버전과 새 버전에 동시에 보내어 테스트
- 사용자에게는 기존 응답만 반환

### 구현 방법 (Kubernetes + Istio Mirroring)

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-app
spec:
  hosts:
    - my-app.example.com
  http:
    - route:
        - destination:
            host: my-app
            subset: stable
    - mirror:
        host: my-app
        subset: shadow
```

---

## 6. Progressive Delivery (점진적 배포)

### 개요

- Canary, Feature Toggle, A/B 테스트 등을 조합하여 점진적으로 배포
- ArgoCD, Flagger 등의 도구 사용

### 구현 방법 (Kubernetes + Argo Rollouts)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: my-app
spec:
  strategy:
    canary:
      steps:
        - setWeight: 20
        - pause: { duration: 10m }
        - setWeight: 50
        - pause: { duration: 30m }
        - setWeight: 100
```

---

## 결론

| 배포 전략             | 특징                 | 추천 시나리오              |
| --------------------- | -------------------- | -------------------------- |
| Rolling Deployment    | 점진적 배포, 안정적  | 일반적인 애플리케이션 배포 |
| Blue-Green Deployment | 빠른 롤백 가능       | 중단 없는 중요 서비스 배포 |
| Canary Deployment     | 점진적 트래픽 이동   | 대규모 사용자 대상 배포    |
| Feature Toggle        | 기능 단위 활성화     | 실험적 기능 배포           |
| Shadow Deployment     | 실 트래픽 테스트     | 성능 테스트 및 신기능 검증 |
| Progressive Delivery  | 자동화된 점진적 배포 | 지속적인 배포 최적화       |
