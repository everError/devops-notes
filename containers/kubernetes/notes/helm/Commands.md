# 📘 Helm 명령어 정리

Helm은 Kubernetes 애플리케이션을 정의, 설치, 관리할 수 있는 패키지 매니저입니다. 아래는 Helm에서 사용하는 주요 명령어들입니다.

## 🔹 설치 및 기본 확인

| 명령어              | 설명                  |
| ---------------- | ------------------- |
| `helm version`   | 설치된 Helm 버전 확인      |
| `helm env`       | Helm 환경 변수 출력       |
| `helm repo list` | 등록된 chart 저장소 목록 확인 |

---

## 🔹 저장소 관리

| 명령어                        | 설명             |
| -------------------------- | -------------- |
| `helm repo add <이름> <URL>` | Chart 저장소 추가   |
| `helm repo update`         | 저장소 업데이트       |
| `helm search repo <키워드>`   | 저장소에서 chart 검색 |

---

## 🔹 Chart 설치 / 삭제 / 업그레이드

| 명령어                            | 설명              |
| ------------------------------ | --------------- |
| `helm install <릴리스이름> <chart>` | Chart를 클러스터에 설치 |
| `helm uninstall <릴리스이름>`       | 설치된 Helm 릴리스 제거 |
| `helm upgrade <릴리스이름> <chart>` | 기존 릴리스를 업그레이드   |

---

## 🔹 값 설정 및 커스터마이징

| 명령어                            | 설명                     |
| ------------------------------ | ---------------------- |
| `helm install -f values.yaml`  | values.yaml 파일로 설정값 주입 |
| `helm install --set key=value` | CLI에서 설정값 직접 주입        |
| `helm get values <릴리스>`        | 현재 릴리스에 적용된 values 확인  |

---

## 🔹 릴리스 상태 및 리소스 확인

| 명령어                       | 설명                    |
| ------------------------- | --------------------- |
| `helm list`               | 현재 네임스페이스에 설치된 릴리스 목록 |
| `helm list -A`            | 모든 네임스페이스의 릴리스 확인     |
| `helm status <릴리스>`       | 릴리스 상세 상태 확인          |
| `helm get manifest <릴리스>` | 실제로 적용된 리소스 YAML 확인   |

---

## 🔹 기타

| 명령어                        | 설명                                 |
| -------------------------- | ---------------------------------- |
| `helm template <chart>`    | 실제 Kubernetes YAML로 변환하여 출력 (적용 X) |
| `helm lint <chart>`        | Chart 문법 및 설정 유효성 검사               |
| `helm show values <chart>` | chart의 기본 values.yaml 내용 출력        |

---