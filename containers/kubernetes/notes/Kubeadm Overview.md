# 📘 kubeadm 개요

## ✅ kubeadm이란?

`kubeadm`은 쿠버네티스(Kubernetes) 클러스터를 빠르고 일관되게 설치 및 초기화할 수 있도록 도와주는 **공식 CLI 도구**입니다. 운영 환경에서 멀티 노드 클러스터를 구축하거나 테스트 환경에서 간단히 클러스터를 구성할 때 사용됩니다.

---

## ⚙️ 주요 기능

| 명령어           | 설명                               |
| ---------------- | ---------------------------------- |
| `kubeadm init`   | 컨트롤 플레인(마스터 노드) 초기화  |
| `kubeadm join`   | 워커 노드를 클러스터에 참여시킴    |
| `kubeadm config` | 클러스터 구성을 생성하거나 검증    |
| `kubeadm reset`  | 클러스터 설정 초기화 및 제거       |
| 인증서 관리      | TLS 인증서 및 kubeconfig 자동 생성 |

> ⚠️ kubeadm은 네트워크 플러그인(CNI), Ingress Controller, Storage Provisioner 등은 **자동 설치하지 않습니다**.

---

## 🧱 kubeadm이 설치하는 핵심 구성 요소

- `kube-apiserver`
- `kube-controller-manager`
- `kube-scheduler`
- `etcd`
- `kubelet`
- `kube-proxy`

---

## 🧪 사용 예시 (기본적인 멀티 노드 구성)

### 1. 마스터 노드에서 초기화

```bash
kubeadm init --pod-network-cidr=10.244.0.0/16
```

### 2. kubeconfig 설정

```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
```

### 3. 네트워크 플러그인 설치 (예: Flannel)

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

### 4. 워커 노드에서 클러스터 참여

```bash
kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

---

## 📌 특징 정리

- 쿠버네티스를 빠르게 설치하고 싶을 때 사용
- 클러스터의 모든 기본 컴포넌트를 설치 및 설정
- 구성의 일관성 보장
- CNI, Ingress 등은 수동 설정 필요
- 로컬 개발보다는 **실제 운영 환경 또는 VM 기반 실습**에 적합

---

## 🔗 참고 자료

- 공식 문서: [https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- GitHub: [https://github.com/kubernetes/kubeadm](https://github.com/kubernetes/kubeadm)
