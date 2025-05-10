# 🧾 HCL (HashiCorp Configuration Language) 개요

Terraform에서 사용되는 HCL(HashiCorp Configuration Language)은 선언형 구성 언어로, 인프라 정의를 간결하고 인간 친화적으로 표현할 수 있도록 설계되었습니다. 이 문서는 HCL의 기본 구조와 개념을 설명합니다.

---

## 🔹 HCL이란?

- **HashiCorp**에서 만든 도메인 특화 언어(DSL)
- JSON과 유사하지만 사람이 읽기 쉬운 구조
- Terraform, Nomad, Consul 등 여러 HashiCorp 제품에서 사용됨

### 특징

- 선언형 언어
- JSON 호환 (원한다면 `.json` 형식으로도 작성 가능)
- 블록 기반 구조로 구성

---

## 🔹 기본 구조

```hcl
resource "aws_instance" "example" {
  ami           = "ami-123456"
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleInstance"
  }
}
```

- `resource`는 블록의 종류
- `"aws_instance"`는 리소스 타입
- `"example"`은 로컬 이름
- 내부 속성은 `key = value` 형태로 기술
- 중첩된 블록은 `{}` 내부에 다시 정의 가능

---

## 🔹 타입과 값

HCL은 기본적으로 다음과 같은 데이터 타입을 사용합니다:

| 타입   | 예시                           |
| ------ | ------------------------------ |
| string | "Hello"                        |
| number | 1, 3.14                        |
| bool   | true, false                    |
| list   | \["a", "b", "c"]               |
| map    | { name = "jaeheon", age = 30 } |
| object | { instance_type = string }     |

```hcl
variable "example" {
  type = object({
    name = string
    tags = map(string)
  })
}
```

---

## 🔹 표현식 (Expressions)

- 변수 참조: `var.name`
- 리소스 참조: `aws_instance.example.id`
- 조건문: `var.is_enabled ? "yes" : "no"`
- 함수 사용: `length(var.list)`, `join(",", var.tags)`

---

## 🔹 내장 함수

HCL에는 다양한 내장 함수가 제공됩니다:

| 함수       | 설명                            |
| ---------- | ------------------------------- |
| `length()` | 리스트나 문자열의 길이 반환     |
| `join()`   | 리스트를 구분자로 이어붙임      |
| `split()`  | 문자열을 분할하여 리스트로 반환 |
| `lookup()` | 맵에서 키 기반 값 검색          |
| `file()`   | 파일 내용 읽기                  |
| `toset()`  | 리스트 → 집합(set)으로 변환     |

---

## 🔹 JSON과의 관계

HCL은 JSON과 1:1 매핑이 가능하므로, 모든 HCL 구성은 JSON으로 변환할 수 있습니다.

예:

```hcl
resource "example" "one" {
  name = "example"
}
```

⬇️ JSON 형식:

```json
{
  "resource": {
    "example": {
      "one": {
        "name": "example"
      }
    }
  }
}
```

---

## ✅ 정리

HCL은 단순한 JSON보다 가독성과 선언성을 강화한 구성 언어입니다. Terraform을 포함한 다양한 도구에서 사용되며, 블록 기반 구성, 표현식, 함수 등의 기능을 통해 유연하고 강력한 설정 파일을 구성할 수 있게 해줍니다.
