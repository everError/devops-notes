# 📦 Helm 차트 패키징 정리

Helm에서는 작성한 차트를 `.tgz` 형식의 패키지로 만들어 배포하거나 저장소에 업로드할 수 있습니다. 이 과정을 **Helm 차트 패키징**이라고 합니다.

---

## 🧱 1. Helm 차트 구조

Helm 차트 디렉토리는 다음과 같은 구조를 가집니다:

```
mychart/
├── Chart.yaml
├── values.yaml
├── charts/
├── templates/
└── ...
```

* `Chart.yaml`: 차트의 이름, 버전, 설명 등을 정의
* `values.yaml`: 기본 변수 값 지정
* `templates/`: 쿠버네티스 리소스 템플릿 위치
* `charts/`: 종속 차트 디렉토리

---

## 🛠️ 2. 차트 패키징

다음 명령어로 Helm 차트를 `.tgz` 형식으로 패키징할 수 있습니다:

```bash
helm package <차트 디렉토리>
```

### 📌 예시:

```bash
helm package ./mychart
```

실행하면 `mychart-1.0.0.tgz` 형식의 패키지 파일이 생성됩니다. (`Chart.yaml`의 `version` 필드 기준)

---

## 📤 3. 패키지된 차트 저장소에 업로드

패키징한 `.tgz` 파일을 HTTP 서버 또는 Helm 저장소에 업로드할 수 있습니다.

### 🔸 로컬 저장소를 생성하려면:

```bash
helm repo index <디렉토리> [--url <베이스 URL>]
```

예:

```bash
helm repo index . --url https://example.com/helm-charts
```

`index.yaml`이 생성되고, 이를 함께 업로드해야 저장소로 인식됩니다.

---

## 🔄 4. 저장소 등록 및 사용

```bash
helm repo add myrepo https://example.com/helm-charts
helm repo update
helm search repo myrepo
```

```bash
helm install my-release myrepo/mychart
```

---

## ✅ 팁

* CI/CD에서 빌드 후 자동 패키징 → 저장소 업로드 → 배포까지 연동 가능
* `--app-version` 플래그로 `Chart.yaml` 내 `appVersion` 오버라이드 가능
* 패키징 전에 Lint 권장: `helm lint ./mychart`