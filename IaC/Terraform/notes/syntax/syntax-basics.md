# 📘 Terraform 문법 기초 정리

Terraform을 사용하기 위한 기본 문법 요소들을 정리합니다. 이 문서는 `.tf` 파일에서 자주 사용되는 구문을 이해하고 작성하는 데 도움을 줍니다.

---

## 🔹 변수 (Variables)

Terraform에서 변수는 외부로부터 입력값을 받아 재사용성과 유연성을 높이는 데 사용됩니다. 보통 `variables.tf` 파일에 정의하며, `terraform.tfvars` 또는 CLI 인자를 통해 값을 전달합니다.

### 입력 변수 정의

```hcl
variable "instance_type" {
  type    = string
  default = "t2.micro"
  description = "EC2 인스턴스의 타입"
}
```

### 변수 값 할당

- `terraform.tfvars` 파일 또는
- CLI 인자: `terraform apply -var="instance_type=t3.small"`

### 변수 참조

```hcl
var.instance_type
```

---

## 🔹 출력값 (Outputs)

output 블록은 실행 결과로부터 중요한 값을 외부에 노출하는 역할을 합니다. 예: IP 주소, ID 등

```hcl
output "instance_ip" {
  value = aws_instance.example.public_ip
  description = "배포된 EC2 인스턴스의 퍼블릭 IP"
}
```

- `terraform output` 명령으로 출력 확인 가능

---

## 🔹 로컬 변수 (Locals)

locals 블록은 계산된 값이나 공통 문자열 등을 저장하여 코드의 중복을 줄이고 가독성을 높이는 데 사용됩니다.

```hcl
locals {
  name_prefix = "dev-"
  full_name   = "${local.name_prefix}web"
}
```

- 참조 방식: `local.full_name`

---

## 🔹 리소스 정의 (Resources)

resource 블록은 실제 인프라(서버, 스토리지, 네트워크 등)를 정의하는 핵심 구성 요소입니다.

```hcl
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = var.instance_type
  tags = {
    Name = "MyInstance"
  }
}
```

- 형식: `resource "<provider>_<type>" "<local name>" { ... }`
- 생성된 리소스는 `aws_instance.example.id`처럼 참조 가능

---

## 🔹 데이터 소스 (Data Source)

data 블록은 기존 리소스의 값을 읽어오거나, 외부의 상태를 참조할 때 사용됩니다.

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
```

- 참조 방식: `data.aws_ami.ubuntu.id`
- 직접 변경할 수는 없음 (읽기 전용)

---

## 🔹 조건문

조건 표현식은 변수나 속성 값을 동적으로 제어할 수 있도록 도와줍니다.

```hcl
instance_type = var.is_production ? "m5.large" : "t3.micro"
```

- `조건 ? 참일 때 값 : 거짓일 때 값` 형식

---

## 🔹 반복문

여러 리소스를 반복 생성할 때 `count` 또는 `for_each`를 사용할 수 있습니다.

### count (숫자 기반 반복)

```hcl
resource "aws_instance" "web" {
  count = 3
  ami           = "ami-123456"
  instance_type = "t2.micro"
  tags = {
    Name = "web-${count.index}"
  }
}
```

### for_each (컬렉션 기반 반복)

```hcl
resource "aws_s3_bucket" "buckets" {
  for_each = toset(["logs", "images", "backups"])
  bucket   = "my-app-${each.key}"
}
```

- `each.key`, `each.value`로 값 접근 가능

---

## 🔹 동적 블록 (dynamic block)

dynamic 블록은 중첩 속성들이 반복되거나 조건부로 존재할 때 동적으로 블록을 생성하는 데 사용됩니다.

```hcl
resource "aws_security_group" "example" {
  name = "example-sg"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

- 블록 이름은 `dynamic "<name>"`으로 지정
- 내부 구조는 `content` 블록 안에 정의

---

## 🔹 주석

Terraform은 HCL(HashiCorp Configuration Language)을 기반으로 하며 주석은 다음과 같이 작성합니다.

```hcl
# 한 줄 주석
// 한 줄 주석
/* 여러 줄 주석 */
```

---

## ✅ 정리

Terraform 문법은 비교적 단순하지만, 선언형 구조에 익숙해지는 것이 중요합니다.
이 문서에서 소개한 각 요소들의 역할과 사용 목적을 명확히 이해하면 다양한 인프라를 효율적으로 코드로 표현할 수 있습니다.
