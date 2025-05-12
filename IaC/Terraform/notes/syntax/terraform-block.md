# ⚙️ `terraform {}` 블록 정리

`terraform {}` 블록은 Terraform 프로젝트의 **전역 설정**을 정의하는 블록입니다. 버전 고정, 백엔드 설정, 기능 플래그 등을 지정하며, 보통 `main.tf` 또는 `provider.tf`에 위치합니다.

---

## 🔹 기본 구조

```hcl
terraform {
  required_version = ">= 1.3.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "my-tf-state-bucket"
    key    = "dev/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
```

---

## ✅ 구성 요소 설명

### 1. `required_version`

- Terraform CLI 버전을 지정합니다.
- 팀 프로젝트나 자동화 환경에서 호환성 문제를 방지할 수 있습니다.

```hcl
required_version = ">= 1.3.0"
```

---

### 2. `required_providers`

- 사용할 provider의 출처(source)와 버전을 명시합니다.
- source는 Terraform Registry 또는 커스텀 레지스트리 경로입니다.

```hcl
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 5.0"
  }
  kubernetes = {
    source  = "hashicorp/kubernetes"
    version = ">= 2.0"
  }
}
```

> `~> 5.0` 은 `>=5.0.0, <6.0.0` 의미

---

### 3. `backend`

- 상태 파일(tfstate)의 저장 위치를 정의합니다.
- 기본값은 `local`이며, **팀 단위 협업**이나 **CI/CD 환경**에서는 보통 원격(Remote) 백엔드를 사용합니다.
- Terraform은 **하나의 backend만 허용**하며, 여러 backend를 동시에 정의할 수 없습니다.

```hcl
backend "s3" {
  bucket         = "terraform-state"
  key            = "project/dev.tfstate"
  region         = "us-west-2"
  dynamodb_table = "terraform-locks"  # 상태 잠금(Locking)을 위한 테이블
  encrypt        = true
}
```

#### ✅ 보안과 제약 사항

- **민감한 데이터 포함**: `.tfstate` 파일에는 비밀번호, 토큰 등 민감한 정보가 평문으로 저장될 수 있으므로 **접근 제어 및 암호화가 중요**합니다.
- **접근 권한 관리**: S3, GCS 등 클라우드 스토리지를 사용하는 경우, IAM 정책 또는 ACL을 통해 접근을 엄격히 제한해야 합니다.
- **state 잠금(Locking)**:

  - 여러 사용자가 동시에 `terraform apply` 등을 수행하면 충돌이 발생할 수 있습니다.
  - `dynamodb_table`을 지정하면 S3 backend에서 잠금(Lock) 기능이 활성화되어 **병행 작업 방지**가 가능합니다.
  - GCS나 Azure backend도 유사한 잠금 메커니즘을 제공합니다.

---

- **지원 백엔드 종류**:

  - `local`: 기본값 (로컬 디스크에 저장)
  - `s3`, `gcs`, `azurerm`: 클라우드 스토리지
  - `consul`, `etcd`, `http`, `remote` 등

---

### 4. `experiments` (비공식)

- 실험적 기능을 활성화할 때 사용합니다 (예: provider dependency lock)
- 현재는 사용 빈도가 낮고 Terraform 버전별 지원이 다름

```hcl
experiments = ["provider_locking"]
```

---

## 📝 예시: 최소 구성

```hcl
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

---

## ✅ 정리

- `terraform {}` 블록은 Terraform 프로젝트의 전역 메타 설정을 위한 블록입니다.
- 주로 Terraform 버전 제한, provider 버전 고정, 백엔드 저장소 설정 등을 관리합니다.
- 협업과 자동화 환경에서 필수적으로 구성해야 하는 블록입니다.
