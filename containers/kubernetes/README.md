# 📘 Kubernetes 개요

## ✅ Kubernetes란?

Kubernetes(쿠버네티스)는 **컨테이너화된 애플리케이션을 자동으로 배포, 스케일링, 운영**하는 오픈소스 플랫폼입니다. Google이 개발하고 CNCF(Cloud Native Computing Foundation)가 유지 관리하며, DevOps와 클라우드 네이티브 환경의 핵심 인프라로 사용됩니다.

---

## 🎯 주요 목적

- 애플리케이션의 **자동 배포 및 관리**
- 컨테이너 기반의 **확장성 높은 인프라 제공**
- **무중단 배포**, **자동 롤백**, **자체 복구(Self-healing)** 지원
- **다양한 환경**(온프레미스, 클라우드, 하이브리드)에서 동일한 방식으로 동작

---

## ⚙️ 핵심 구성 요소

| 구성 요소              | 설명                                           |
| ---------------------- | ---------------------------------------------- |
| **Pod**                | 하나 이상의 컨테이너를 포함하는 최소 실행 단위 |
| **Node**               | 실제 작업을 수행하는 서버 (물리/가상)          |
| **Cluster**            | 여러 노드로 구성된 전체 쿠버네티스 시스템      |
| **Deployment**         | 애플리케이션 배포 및 업데이트 전략 정의        |
| **Service**            | Pod에 대한 네트워크 접근을 위한 추상화 계층    |
| **ConfigMap / Secret** | 환경 변수 및 민감 정보를 외부 설정으로 관리    |
| **Volume / PVC**       | 영속적인 저장소와의 연결                       |

---

## 🔧 작동 구조 요약

```plaintext
[User / DevOps]
     ↓ kubectl
[API Server (Control Plane)]
     ↓
Scheduler ─ Controller Manager ─ etcd (DB)
     ↓
[Worker Nodes]
  ├─ kubelet
  ├─ kube-proxy
  └─ Pods (컨테이너)
```

---

## 🔍 주요 특징

- **Self-healing**: 장애 발생 시 자동 복구
- **Horizontal Scaling**: 부하에 따라 Pod 수 자동 조절 (HPA)
- **Service Discovery & Load Balancing**: 자동 DNS/로드밸런싱
- **Rolling Update / Rollback**: 애플리케이션 무중단 배포 가능
- **Declarative 구성**: YAML 정의로 상태 관리
- **플랫폼 독립적**: 온프레미스/클라우드 어디서나 동일하게 작동

---

## 🧪 실습 예시

```bash
# Nginx 애플리케이션 배포
kubectl create deployment nginx --image=nginx

# 서비스 생성 (NodePort로 노출)
kubectl expose deployment nginx --port=80 --type=NodePort

# 서비스 확인
kubectl get svc
```

---

## ☁️ Kubernetes를 제공하는 플랫폼

| 플랫폼          | 설명                               |
| --------------- | ---------------------------------- |
| AWS EKS         | Amazon Elastic Kubernetes Service  |
| Azure AKS       | Microsoft Azure Kubernetes Service |
| GCP GKE         | Google Kubernetes Engine           |
| Minikube / Kind | 로컬 개발 환경                     |
| kubeadm         | 온프레미스 직접 설치 도구          |

---

## 🔗 참고 자료

- 공식 홈페이지: [https://kubernetes.io/](https://kubernetes.io/)
- GitHub: [https://github.com/kubernetes/kubernetes](https://github.com/kubernetes/kubernetes)
- 아키텍처 개요: [https://kubernetes.io/docs/concepts/overview/components/](https://kubernetes.io/docs/concepts/overview/components/)
