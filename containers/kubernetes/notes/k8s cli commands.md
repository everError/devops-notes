# 📘 Kubernetes 주요 명령어 정리 (kubectl)

Kubernetes에서는 `kubectl` 명령어를 통해 클러스터를 관리하고 리소스를 조작합니다. 아래는 실무 및 실습에서 자주 사용하는 `kubectl` 명령어들을 목적별로 정리한 내용입니다.

---

## 🔹 클러스터 정보 확인

| 명령어                              | 설명                                 |
| ----------------------------------- | ------------------------------------ |
| `kubectl cluster-info`              | 현재 클러스터의 엔드포인트 정보 확인 |
| `kubectl config view`               | 현재 사용 중인 kubeconfig 설정 확인  |
| `kubectl config use-context <이름>` | 사용할 클러스터 컨텍스트 전환        |
| `kubectl get nodes`                 | 클러스터에 등록된 노드 목록 확인     |

---

## 🔹 리소스 조회

| 명령어                            | 설명                                         |
| --------------------------------- | -------------------------------------------- |
| `kubectl get pods`                | 모든 Pod 조회 (기본은 default namespace)     |
| `kubectl get svc`                 | 모든 Service 조회                            |
| `kubectl get deployment`          | 모든 Deployment 조회                         |
| `kubectl get all`                 | Pod, Service, Deployment 등 전체 리소스 조회 |
| `kubectl get pods -n <namespace>` | 특정 네임스페이스의 Pod 조회                 |

---

## 🔹 리소스 생성 및 적용

| 명령어                                                                    | 설명                                                  |
| ------------------------------------------------------------------------- | ----------------------------------------------------- |
| `kubectl apply -f <파일>`                                                 | YAML 파일 기반으로 리소스를 생성 또는 업데이트        |
| `kubectl create namespace <이름>`                                         | 네임스페이스 생성                                     |
| `kubectl create -f <파일>`                                                | YAML로 리소스 생성 (apply와 유사하나 업데이트는 불가) |
| `kubectl create deployment my-app --image=nginx --dry-run=client -o yaml` | 실제 생성하지 않고 YAML 출력 (템플릿 확인용)          |

---

## 🔹 리소스 수정 및 삭제

| 명령어                               | 설명                             |
| ------------------------------------ | -------------------------------- |
| `kubectl edit <리소스타입> <이름>`   | 리소스 YAML을 에디터로 직접 수정 |
| `kubectl delete -f <파일>`           | YAML에 정의된 리소스 삭제        |
| `kubectl delete <리소스타입> <이름>` | 특정 리소스 삭제                 |

---

## 🔹 Pod / 컨테이너 내부 접근 및 로그 확인

| 명령어                             | 설명                           |
| ---------------------------------- | ------------------------------ |
| `kubectl exec -it <pod명> -- bash` | Pod 내부 bash 접속             |
| `kubectl logs <pod명>`             | Pod 로그 출력                  |
| `kubectl logs -f <pod명>`          | 로그 실시간 출력 (follow 모드) |
| `kubectl describe pod <pod명>`     | Pod 상세 상태 확인             |

---

## 🔹 기타 유용한 명령어

| 명령어                                                   | 설명                                             |
| -------------------------------------------------------- | ------------------------------------------------ |
| `kubectl port-forward <pod명> <로컬포트>:<컨테이너포트>` | 로컬에서 Pod의 포트 접근                         |
| `kubectl get events`                                     | 최근 이벤트 확인 (에러, 스케줄 등 디버깅에 도움) |
| `kubectl explain <리소스타입>`                           | 해당 리소스의 구조와 설명 출력                   |

---

## 🔸 옵션: `--dry-run`

| 옵션               | 설명                                                            |
| ------------------ | --------------------------------------------------------------- |
| `--dry-run=client` | 실제 리소스를 생성하지 않고 클라이언트 측에서 YAML만 시뮬레이션 |
| `--dry-run=server` | API 서버에 유효성만 검사, 적용은 안 함                          |

### 예시

```bash
kubectl apply -f deployment.yaml --dry-run=client -o yaml
```

```bash
kubectl create deployment my-app --image=nginx --dry-run=client -o yaml > deployment.yaml
```

- 테스트 또는 템플릿 생성을 위한 안전한 방식으로 유용함

---

## 📌 팁

- `-o yaml` 옵션으로 출력 포맷을 YAML로 확인할 수 있습니다.
- `--namespace` 옵션 또는 `-n` 플래그로 네임스페이스를 지정할 수 있습니다.
- `kubectl apply -k ./경로` 로 Kustomize 디렉토리를 적용할 수 있습니다.
