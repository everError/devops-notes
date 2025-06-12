# 📘 Kubernetes ConfigMap 가이드

`ConfigMap`은 Kubernetes에서 **애플리케이션 설정 값을 분리**하여 관리할 수 있도록 도와주는 리소스입니다. 코드와 설정을 분리함으로써 애플리케이션을 더 유연하게 배포할 수 있게 해줍니다.

---

## 🔹 ConfigMap이란?

- 환경 변수, 설정 파일, 커맨드라인 인자 등에 사용할 **비밀이 아닌 설정 데이터**를 저장하는 객체
- 하나의 ConfigMap은 여러 키-값 쌍을 포함할 수 있음
- **Deployment**, **Pod** 등에서 참조 가능

---

## 🔸 ConfigMap 생성 방법

### 1. 명령어로 생성

```bash
kubectl create configmap my-config \
  --from-literal=APP_ENV=production \
  --from-literal=APP_VERSION=1.2.3
```

### 2. 파일로부터 생성

```bash
kubectl create configmap my-config --from-file=./app-config.yaml
```

### 3. YAML로 직접 작성

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
  namespace: default

data:
  APP_ENV: production
  APP_VERSION: "1.2.3"
  config.yaml: |
    debug: false
    timeout: 30
```

---

## 🔸 Pod에서 ConfigMap 사용하기

### 1. 환경 변수로 주입

```yaml
spec:
  containers:
    - name: my-app
      image: nginx
      env:
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: my-config
              key: APP_ENV
```

### 2. 전체 ConfigMap을 환경 변수로 주입

```yaml
envFrom:
  - configMapRef:
      name: my-config
```

### 3. Volume으로 마운트

```yaml
volumes:
  - name: config-volume
    configMap:
      name: my-config

containers:
  - name: my-app
    volumeMounts:
      - name: config-volume
        mountPath: /etc/config
```

이렇게 하면 `/etc/config/APP_ENV`, `/etc/config/config.yaml` 등의 파일로 접근 가능함

---

## 📌 주의 사항

- ConfigMap은 **비밀 값을 저장하지 않음** → 비밀번호 등은 `Secret` 사용
- ConfigMap 수정 시, 자동으로 Pod가 재시작되지 않음

  - 재시작하려면 `kubectl rollout restart deployment <이름>` 필요

---

## 🔍 ConfigMap 확인 및 관리 명령어

| 명령어                              | 설명                     |
| ----------------------------------- | ------------------------ |
| `kubectl get configmap`             | 전체 ConfigMap 목록 확인 |
| `kubectl describe configmap <이름>` | 상세 정보 확인           |
| `kubectl edit configmap <이름>`     | 인라인 수정 (vi 편집기)  |
| `kubectl delete configmap <이름>`   | 삭제                     |
