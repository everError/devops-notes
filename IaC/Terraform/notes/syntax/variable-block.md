# 🧮 Terraform 변수 (`variable`) 블록 정리

`variable` 블록은 Terraform에서 **사용자 정의 입력값을 선언**하는 데 사용됩니다. 환경에 따라 유동적인 값을 받아 인프라 구성을 더 유연하고 재사용 가능하게 만들 수 있습니다.

---

## 📌 기본 구조

```hcl
variable "<name>" {
  type        = <type>           # 선택: string, number, bool, list, map, object 등
  default     = <default_value>  # 선택: 기본값 지정
  description = "설명"           # 선택: 문서화 목적
  nullable    = true/false       # 선택: null 허용 여부 (기본 true)
  sensitive   = true/false       # 선택: 출력 숨김 여부
  validation {
    condition     = <expression>
    error_message = "조건이 false일 경우 표시할 에러 메시지"
  }
}
```

- `<name>`: 이 변수를 참조할 때 사용할 이름
- `type`: 값의 자료형 명시 (`string`, `bool`, `list(string)` 등)
- `default`: 생략 시 필수 입력값으로 간주됨
- `validation`: 조건식과 오류 메시지를 지정하여 유효성 검사 수행 (Terraform ≥ 0.13)

---

## 🔹 예시: 기본 변수 선언

```hcl
variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 인스턴스 타입"
}
```

```hcl
variable "allowed_ports" {
  type    = list(number)
  default = [22, 80, 443]
}
```

---

## 🔹 변수 값 주입 방법

Terraform은 여러 위치에서 변수 값을 주입할 수 있으며, 아래와 같은 **우선순위**로 적용됩니다 (위가 가장 낮고, 아래로 갈수록 우선순위가 높음):

1. `default` 값 (코드 내부에 명시된 기본값)
2. `.tfvars` 또는 `.tfvars.json` 파일
3. `terraform.tfvars` 파일 (자동 인식됨)
4. `*.auto.tfvars` 파일 (자동 인식됨)
5. 명령줄 `-var` 또는 `-var-file` 인자
6. 환경 변수 (형식: `TF_VAR_<variable_name>`)

> 동일한 변수에 대해 여러 값이 제공될 경우, 우선순위가 가장 높은 항목이 적용됩니다.

예시:

```bash
terraform apply -var="instance_type=m5.large"
```

또는:

```bash
export TF_VAR_instance_type=m5.large
```

---

## 🔹 변수 참조

```hcl
resource "aws_instance" "web" {
  instance_type = var.instance_type
}
```

- 변수 참조는 항상 `var.<name>` 형식을 사용

---

## 🔹 복합 타입 예시

### ✅ 객체(Object)

```hcl
variable "vm_config" {
  type = object({
    instance_type = string
    subnet_id     = string
  })
}
```

### ✅ 맵(Map)

```hcl
variable "user_tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Owner       = "team"
  }
}
```

---

## 🔹 민감한 값 처리 (`sensitive = true`)

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

- `terraform plan` 또는 `output` 출력에서 마스킹 처리됨
- 보안 정보 입력 시 유용

---

## 🔹 유효성 검사 (`validation`)

Terraform ≥ 0.13부터 `validation` 블록을 통해 변수 입력값의 유효성을 검증할 수 있습니다.

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "environment 변수는 dev, stage, prod 중 하나여야 합니다."
  }
}
```

- 조건이 false일 경우 apply 시 에러 발생
- 복잡한 조건도 `regex`, `length()`, `can()` 등과 조합 가능

---

## ✅ 정리

- `variable` 블록은 **사용자 입력값을 정의**하고 코드 내에서 유연하게 활용하는 핵심 수단입니다.
- 다양한 타입과 기본값을 통해 복잡한 구성을 단순화할 수 있으며,
- `tfvars`, 환경 변수, CLI 인자 등 다양한 방법으로 값을 주입할 수 있고, 그 우선순위를 이해하는 것이 중요합니다.
- `sensitive`, `nullable`, `validation`과 같은 고급 옵션을 통해 **보안과 유효성**도 함께 관리할 수 있습니다.
