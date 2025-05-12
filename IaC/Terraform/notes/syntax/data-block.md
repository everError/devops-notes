# 📖 Terraform 데이터 소스 (`data`) 블록 정리

Terraform의 `data` 블록은 **이미 존재하는 외부 리소스나 상태를 읽어오기 위해 사용**됩니다. 직접 생성하는 것이 아닌 **읽기 전용(Read-only)** 으로 외부 정보를 가져와 다른 리소스에서 활용할 수 있도록 도와줍니다.

---

## 📌 기본 구조

```hcl
data "<provider>_<type>" "<local_name>" {
  ...arguments...
}
```

- `<provider>_<type>`: 조회할 리소스의 종류 (예: `aws_ami`, `azurerm_resource_group`)
- `<local_name>`: 내부에서 참조할 수 있는 이름
- 인수(Arguments)를 통해 어떤 조건으로 데이터를 조회할지 명시

---

## 🔹 예시: 최신 Ubuntu AMI 조회

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
```

- AWS에서 가장 최근의 Ubuntu 20.04 AMI를 가져오는 예시
- 이후 다른 리소스에서 다음처럼 참조 가능:

```hcl
ami = data.aws_ami.ubuntu.id
```

---

## 🔹 사용 목적

- 최신 이미지, 리전, 가용 영역 정보 등 동적 데이터 참조
- 이미 생성된 인프라 자원을 참조 (e.g. VPC, 보안 그룹, IAM Role)
- 수동 관리 중인 외부 자원을 코드로 활용 (but 생성 X)

---

## 🔹 주요 예시

### ✅ 기존 VPC 조회

```hcl
data "aws_vpc" "default" {
  default = true
}
```

### ✅ IAM Role 정보 조회

```hcl
data "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"
}
```

### ✅ S3 버킷 존재 여부 확인 (간접적으로)

```hcl
data "aws_s3_bucket" "logs" {
  bucket = "my-log-bucket"
}
```

> 주의: `data` 블록은 리소스 존재를 보장하지 않으므로 예외 처리를 하거나 `terraform plan` 시 오류가 날 수 있습니다.

---

## 🔹 조건문과 결합

```hcl
locals {
  ami_id = var.use_custom_ami ? var.custom_ami_id : data.aws_ami.ubuntu.id
}
```

- 변수 조건에 따라 데이터 소스의 값을 사용할지 결정

---

## 🔹 반복문과 결합 (for_each)

데이터 소스는 `for_each`를 통해 반복적으로 참조할 수 있습니다 (Terraform 0.12+).

```hcl
data "aws_iam_policy" "managed" {
  for_each = toset(["AmazonS3ReadOnlyAccess", "CloudWatchFullAccess"])
  name     = each.key
}
```

---

## ✅ 정리

- `data` 블록은 Terraform이 **읽기 전용 외부 정보**를 가져오는 도구입니다.
- `resource`와 달리 실제 인프라를 생성하지 않으며, **의존성 추적과 구성 유연성** 확보에 매우 유용합니다.
- 자주 사용하는 provider마다 다양한 데이터 소스가 존재하므로 공식 문서를 참고하여 필요한 데이터를 정확히 가져올 수 있습니다.
