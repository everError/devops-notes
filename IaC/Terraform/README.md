# 🛠 Terraform 학습 및 실습

이 문서는 Infrastructure as Code(IaC) 도구인 **Terraform**에 대한 학습과 실습을 기록하기 위한 문서입니다. Terraform을 사용하면 **인프라 자원을 코드로 정의하고 자동으로 배포 및 관리**할 수 있습니다.

---

## 📌 Terraform 개요

### Terraform이란?

- HashiCorp에서 개발한 오픈소스 **IaC(Infrastructure as Code)** 도구
- HCL(HashiCorp Configuration Language)이라는 선언형 문법을 사용
- AWS, Azure, GCP, Docker, Kubernetes 등 다양한 클라우드 및 플랫폼을 지원

### 주요 특징

- **Provider 기반**: 클라우드/인프라 플랫폼마다 Provider 제공 (예: `aws`, `azurerm`, `kubernetes`, `docker`)
- **Declarative(선언형) 문법**: 어떤 상태가 되어야 하는지만 기술
- **State 관리**: 현재 인프라 상태를 `.tfstate` 파일로 관리하여 원하는 상태와 비교 후 변경
- **Plan → Apply → Destroy** 흐름
