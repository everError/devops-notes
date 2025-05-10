# 🧱 Terraform 리소스 블록 정리

`resource` 블록은 Terraform에서 **실제 인프라를 정의**하는 핵심 구성 요소입니다. 서버, 데이터베이스, 스토리지, 네트워크 등의 인프라 자원을 생성할 때 사용됩니다.

---

## 📌 기본 구조

```hcl
resource "<provider>_<type>" "<local_name>" {
  key1 = value1
  key2 = value2
  ...
}
```

- `<provider>_<type>`: 생성할 리소스의 종류 (예: `aws_instance`, `azurerm_storage_account`)
- `<local_name>`: 리소스를 참조할 수 있는 내부 이름 (사용자 정의)
- 내부 속성들은 해당 리소스의 세부 설정 값들

---

## 🔹 예시: AWS EC2 인스턴스

```hcl
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "MyExampleInstance"
  }
}
```

- `aws_instance`: AWS의 EC2 인스턴스 리소스
- `example`: 해당 리소스를 참조할 때 사용할 이름
- `ami`, `instance_type`, `tags`는 이 리소스가 요구하는 속성들

---

## 🔹 참조 방식

다른 리소스나 변수에서 이 리소스를 참조할 때는 다음과 같이 사용합니다:

```hcl
aws_instance.example.id
```

형식: `<resource_type>.<local_name>.<property>`

- 예: `aws_security_group.web.id`를 EC2 인스턴스에 참조하면 해당 보안 그룹이 자동으로 연결됨

> Terraform은 이처럼 속성 참조를 통해 리소스 간 **암묵적인 의존성**을 생성합니다.

---

## 🔹 명시적 종속성 (`depends_on`)

Terraform은 속성 참조를 통해 암묵적인 의존성을 추론하지만, 복잡한 의존 관계가 있을 경우 `depends_on`을 통해 명시적으로 선언할 수 있습니다.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-123456"
  instance_type = "t2.micro"

  depends_on = [aws_security_group.web]
}
```

- `depends_on`은 해당 리소스가 다른 리소스보다 **먼저 생성되어야 함을 보장**합니다.

---

## 🔹 리소스 블록의 반복 생성

여러 개의 리소스를 반복적으로 생성하고 싶을 때는 `count` 또는 `for_each`를 사용할 수 있습니다.

### ✅ `count` 예시:

```hcl
resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  tags = {
    Name = "web-${count.index}"
  }
}
```

### ✅ `for_each` 예시:

```hcl
resource "aws_s3_bucket" "buckets" {
  for_each = toset(["images", "logs", "backup"])
  bucket   = "my-app-${each.key}"
  acl      = "private"
}
```

---

## 🔹 수명 주기 설정 (`lifecycle`)

`lifecycle` 블록은 리소스 생성, 변경, 삭제 동작에 대한 세밀한 제어를 제공합니다.

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-example-bucket"

  lifecycle {
    prevent_destroy      = true
    ignore_changes       = [tags]
    create_before_destroy = true
  }
}
```

### 주요 속성 설명:

- `prevent_destroy`: 이 리소스가 실수로 삭제되는 것을 방지. 삭제 시 오류 발생
- `ignore_changes`: 지정된 속성 변경을 무시하고 무시한 채 적용 (e.g. `tags`)
- `create_before_destroy`: 변경 시 기존 리소스를 먼저 삭제하는 대신, 새로 생성한 뒤 기존 리소스를 삭제 (Zero Downtime 대응)

### ✅ 조건부 제약 설정 (Terraform >= 1.2)

```hcl
resource "aws_instance" "example" {
  ami           = "ami-123"
  instance_type = "t2.micro"

  lifecycle {
    precondition {
      condition     = var.create_instance
      error_message = "변수가 false이면 인스턴스를 만들 수 없습니다."
    }

    postcondition {
      condition     = self.instance_type != "t3.nano"
      error_message = "t3.nano는 성능이 너무 낮습니다."
    }
  }
```

- `precondition`: apply 전에 검증 (조건이 false면 적용 실패)
- `postcondition`: 리소스가 적용된 후 검증 (적용 후 상태 조건 검사)

---

## 🔹 중첩 블록 (Nested Blocks)

일부 리소스는 내부에 추가적인 블록을 포함할 수 있습니다.

```hcl
resource "aws_security_group" "example" {
  name = "example-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

- `ingress`, `egress` 등은 중첩 블록의 예입니다.

---

## 🔹 구성 및 속성 참조 주의사항

- 참조할 속성이 **존재하지 않거나 null일 경우 에러가 발생**할 수 있으므로 `optional`, `null`, `try()` 함수를 활용할 수 있습니다.
- 변수 및 리소스 속성을 **동적으로 조합할 경우 문자열 보간법 `${}`** 또는 `templatefile()`을 사용할 수 있습니다.
- 리소스 이름 변경 시 참조 대상이 바뀌는 것에 유의해야 하며, **리팩토링 시 리소스 교체가 발생할 수 있습니다**.

---

## ✅ 정리

- `resource` 블록은 Terraform의 가장 핵심적인 구성으로 실제 인프라 리소스를 생성합니다.
- 각 리소스는 provider + type + 로컬 이름으로 고유하게 식별됩니다.
- 반복 생성, 수명 주기 제어, 참조, 종속성, 중첩 블록 등 다양한 확장 구문이 존재하며, 선언형으로 인프라 구성을 유연하게 관리할 수 있습니다.
