# Tekton 설치 및 확인 절차

Tekton과 관련 도구들을 설치하고 정상적으로 작동하는지 확인하는 전체 과정입니다.

-----

### 1\. Tekton 핵심 컴포넌트 설치

Kubernetes 클러스터에 Tekton의 주요 구성 요소인 **Pipelines**, **Triggers**, **Dashboard**를 설치합니다.

```bash
# 1. Tekton Pipelines 설치 (핵심 엔진)
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

# 2. Tekton Triggers 설치 (이벤트 기반 파이프라인 실행)
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml

# 3. Tekton Dashboard 설치 (웹 UI)
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml
```

-----

### 2\. Tekton Dashboard 접속

로컬 PC에서 웹 브라우저를 통해 Tekton 대시보드에 접속하기 위해 **포트 포워딩**을 설정합니다.

```bash
# tekton-dashboard 서비스를 로컬 9097 포트로 연결
kubectl port-forward --namespace tekton-pipelines service/tekton-dashboard 9097:9097
```

이제 웹 브라우저에서 `http://localhost:9097` 주소로 접속하여 대시보드를 확인할 수 있습니다.

-----

### 3\. Tekton CLI (tkn) 설치

커맨드 라인에서 Tekton을 편리하게 관리하기 위한 CLI 도구 `tkn`을 설치합니다. (Windows, Chocolatey 기준)

```powershell
# Chocolatey를 사용하여 Tekton CLI 설치
choco install tektoncd-cli --confirm
```

-----

### 4\. 최종 버전 확인

모든 설치가 완료된 후, `tkn` 명령어를 사용하여 설치된 전체 컴포넌트의 버전을 최종적으로 확인합니다.

```bash
# 설치된 Client, Pipeline, Triggers, Dashboard 버전 확인
tkn version
```