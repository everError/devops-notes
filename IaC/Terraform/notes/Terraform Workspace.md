# Terraform Workspace 정리

## 📌 Terraform Workspace란?

Terraform Workspace는 하나의 Terraform 구성(Configuration)으로 **여러 개의 독립된 상태(state)를 관리**할 수 있게 해주는 기능입니다. 동일한 인프라 정의를 공유하면서도 서로 다른 환경(예: dev, staging, prod)에 대해 각각의 상태 파일을 사용할 수 있습니다.

---

## 🔹 Workspace의 개념

| 항목                     | 설명                                                                                |
| ------------------------ | ----------------------------------------------------------------------------------- |
| 기본 워크스페이스        | `default`라는 이름의 기본 워크스페이스가 존재하며, 명시적 설정이 없으면 이를 사용함 |
| 사용자 정의 워크스페이스 | `terraform workspace new <이름>` 명령어로 새로운 워크스페이스 생성 가능             |
| 상태 파일 분리           | 워크스페이스마다 별도의 상태 파일을 관리하므로 환경별 분리가 용이함                 |

---

## 🔸 사용 예시

```bash
# 현재 워크스페이스 확인
terraform workspace show

# 워크스페이스 목록 조회
terraform workspace list

# 새 워크스페이스 생성
terraform workspace new dev

# 기존 워크스페이스로 전환
terraform workspace select prod

# 워크스페이스 삭제
terraform workspace delete dev
```

---

## 🔹 Workspace 동작 원리

- 워크스페이스를 변경하면 Terraform은 **해당 워크스페이스 전용의 상태 파일**을 사용합니다.
- 로컬 backend에서는 `.terraform/` 내부에 워크스페이스별 디렉터리를 만들어 상태를 구분합니다.
- 원격 backend(S3 등)에서는 키(prefix)에 워크스페이스 이름이 포함되어 저장됩니다:

  ```
  s3://my-bucket/terraform.tfstate         # default 워크스페이스
  s3://my-bucket/env:/dev/terraform.tfstate # dev 워크스페이스
  ```

---

## 🔸 변수와 워크스페이스

워크스페이스를 기반으로 변수 값을 다르게 설정하려면 `terraform.tfvars` 파일 또는 조건문을 활용할 수 있습니다.

```hcl
variable "env_name" {
  default = "default"
}

locals {
  env_prefix = terraform.workspace == "default" ? "" : "${terraform.workspace}-"
}
```

---

## ⚠️ 주의사항

- 워크스페이스는 \*\*구성 파일(HCL)\*\*을 바꾸지 않고도 여러 환경을 분리할 수 있다는 장점이 있지만, **완전한 환경 분리를 위해 디렉터리 분리**를 병행하는 것이 권장됨
- 상태 파일이 분리되어 있어도 **모든 환경이 동일한 코드로부터 영향을 받음** → 실수 방지 필요

---

## ✅ 요약

- Workspace는 동일한 Terraform 코드로 여러 상태를 관리할 수 있도록 해줌
- `terraform workspace` 명령어로 생성, 전환, 삭제 가능
- 상태 파일은 워크스페이스마다 분리되어 저장됨
- 환경별 코드 실행을 분리할 때 유용하나, 완전한 격리는 디렉터리 또는 모듈 분리와 병행 필요
