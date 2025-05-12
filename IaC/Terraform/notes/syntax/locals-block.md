# 🧩 Terraform 로컬 변수 (`locals`) 블록 정리

`locals` 블록은 Terraform에서 **중간 계산 값이나 재사용되는 표현식**을 정의할 때 사용됩니다. 코드의 중복을 줄이고 가독성을 높이는 데 유용합니다.

---

## 📌 기본 구조

```hcl
locals {
  <name1> = <expression1>
  <name2> = <expression2>
  ...
}
```

- `locals`는 여러 개의 로컬 변수를 한 번에 정의 가능
- 각 값은 표현식, 변수, 함수 등을 포함할 수 있음

---

## 🔹 예시: 문자열과 조건 처리

```hcl
locals {
  name_prefix = "dev"
  full_name   = "${local.name_prefix}-app"
  is_prod     = var.environment == "prod"
}
```

- `local.name_prefix`: 직접 정의한 값
- `local.full_name`: 다른 로컬 변수를 참조 가능
- `local.is_prod`: 조건 표현식 사용 가능

---

## 🔹 리스트, 맵, 반복 구조 활용

```hcl
locals {
  environments = ["dev", "stage", "prod"]

  default_tags = {
    Owner      = "infra-team"
    ManagedBy  = "terraform"
  }

  upper_envs = [for env in local.environments : upper(env)]
}
```

- 리스트 및 맵도 정의 가능
- `for` 표현식을 통해 동적 가공 처리 가능

---

## 🔹 복잡한 조건 처리

```hcl
locals {
  instance_type = var.environment == "prod" ? "m5.large" : "t3.micro"
}
```

- 조건 삼항 연산자 (`? :`)를 활용해 환경에 따라 다른 값을 반환

---

## 🔹 `local` 변수의 참조 방식

```hcl
resource "aws_instance" "example" {
  instance_type = local.instance_type
  tags          = local.default_tags
}
```

- `local.<name>` 형식으로 참조

---

## 🔹 변수와의 차이점

| 항목        | `variable`                 | `locals`                    |
| ----------- | -------------------------- | --------------------------- |
| 입력 방식   | 사용자 입력                | 코드 내부 정의              |
| 변경 가능성 | 외부 환경에 따라 변경 가능 | 고정 값 (계산 결과)         |
| 참조 방식   | `var.<name>`               | `local.<name>`              |
| 용도        | 외부 구성 유연성 확보      | 중복 제거, 계산된 값 재사용 |

---

## ✅ 정리

- `locals` 블록은 코드 내부에서 **계산된 값, 중복되는 표현식, 조건 결과 등을 재사용**할 때 유용합니다.
- 다른 변수(`var.`), 다른 로컬 값(`local.`), 함수, 조건식과 함께 사용할 수 있습니다.
- 리소스 구성 시 가독성을 높이고, 유지보수를 용이하게 만드는 도구입니다.
