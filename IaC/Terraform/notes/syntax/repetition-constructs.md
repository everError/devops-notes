# 🔁 Terraform 반복문 정리 (`count`, `for_each`, `for`, `dynamic`)

Terraform은 선언형 언어이지만, 반복 구문을 지원하여 **리소스를 여러 개 생성하거나 속성을 동적으로 구성**할 수 있습니다.
여기서는 반복 관련 핵심 구문들을 정리합니다.

---

## 1️⃣ `count`

`count`는 동일한 리소스를 **정해진 개수만큼 반복 생성**할 때 사용합니다.

```hcl
resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-123456"
  instance_type = "t2.micro"
  tags = {
    Name = "web-${count.index}"
  }
}
```

- `count.index`: 0부터 시작하는 반복 인덱스
- 리소스 참조 시 `aws_instance.web[0]`, `[1]` 등 배열로 접근

> `count = 0`으로 설정하면 해당 리소스 생성을 건너뜁니다.

---

## 2️⃣ `for_each`

`for_each`는 **맵 또는 집합(Set)** 자료구조를 기반으로 반복 생성합니다.

```hcl
resource "aws_s3_bucket" "bucket" {
  for_each = toset(["logs", "images", "backup"])

  bucket = "my-app-${each.key}"
  acl    = "private"
}
```

- `each.key`: 현재 반복 중인 항목의 키 (문자열)
- `each.value`: (맵일 경우) 해당 키의 값

> `for_each`는 각 리소스에 **고유 키가 부여되므로** 변경 추적이 `count`보다 안정적입니다.

---

## 3️⃣ `for` 표현식 (리스트/맵 변환)

`for`는 주로 `locals`, `output`, `resource`의 속성 값 생성 시 사용됩니다.

### ✅ 리스트 변환

```hcl
locals {
  upper_envs = [for env in ["dev", "stage"] : upper(env)]
}
```

### ✅ 맵 변환

```hcl
locals {
  tag_map = {
    for name in ["db", "cache"] :
    name => "app-${name}"
  }
}
```

- 조건부 포함:

```hcl
locals {
  filtered = [for v in var.ports : v if v != 22]
}
```

---

## 4️⃣ `dynamic` 블록

`dynamic`은 **중첩 블록을 반복적으로 정의**할 때 사용됩니다. 보통 `ingress`, `egress` 등 블록형 속성에서 활용됩니다.

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

- `dynamic "<block_name>"` 으로 시작
- `for_each`로 반복 대상 지정
- `content` 블록 안에 실제 내용 작성

---

## ✅ 선택 기준 요약

| 목적           | 구문       | 특징                                         |
| -------------- | ---------- | -------------------------------------------- |
| 개수 기반 반복 | `count`    | 인덱스 기반, 배열처럼 참조 (`[0]`, `[1]`...) |
| 키 기반 반복   | `for_each` | 맵/셋 기반 반복, 리소스 이름 고유함          |
| 속성/값 변환   | `for`      | 리스트/맵 생성용 표현식                      |
| 중첩 블록 반복 | `dynamic`  | 블록 내 반복이 필요할 때                     |

---

## ✅ 정리

- `count`와 `for_each`는 리소스 반복 생성에 사용되며 상황에 따라 선택
- `for`는 리스트/맵 구성용으로 선언적 코드에 유용
- `dynamic`은 복잡한 블록 반복을 유연하게 처리
