# 📤 Terraform 출력값 (`output`) 블록 정리

`output` 블록은 Terraform 실행 결과에서 **중요한 값을 외부로 노출하거나 다른 모듈에 전달**하기 위해 사용됩니다.
주로 리소스 ID, IP 주소, URL, ARN 등 사용자에게 필요한 정보나 모듈 간 데이터 전달에 활용됩니다.

---

## 📌 기본 구조

```hcl
output "<name>" {
  value       = <expression>     # 필수: 출력할 값
  description = "설명"           # 선택: 출력 항목 설명
  sensitive   = true/false       # 선택: 민감한 값은 출력 시 마스킹
  depends_on  = [<resources>]    # 선택: 출력값 계산 전 의존성 명시
}
```

- `<name>`: 출력 변수 이름 (명령어 또는 모듈에서 참조됨)
- `value`: 출력할 실제 값 (리소스 속성, 변수, 계산식 등)
- `sensitive`: `true`일 경우 `terraform output` 명령 시 값이 숨김 처리됨

---

## 🔹 기본 예시

```hcl
output "instance_ip" {
  value       = aws_instance.web.public_ip
  description = "웹 서버의 퍼블릭 IP 주소"
}
```

실행 후 확인:

```bash
terraform apply
terraform output instance_ip
```

전체 출력:

```bash
terraform output
```

---

## 🔹 민감한 값 숨기기

```hcl
output "db_password" {
  value     = var.db_password
  sensitive = true
}
```

- `terraform output` 시 `db_password = <sensitive>` 로 표시됨
- 실제 스크립트 내부에선 정상적으로 값 사용 가능

---

## 🔹 모듈 간 출력 전달

`output` 블록은 상위 모듈에서 하위 모듈의 값을 참조할 수 있게 합니다.

### 하위 모듈 (modules/network/outputs.tf)

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}
```

### 상위 모듈 (main.tf)

```hcl
module "network" {
  source = "./modules/network"
}

resource "aws_subnet" "subnet" {
  vpc_id = module.network.vpc_id
  ...
}
```

- 상위에서 `module.<module_name>.<output_name>` 형태로 접근

---

## 🔹 조건부 출력

```hcl
output "dashboard_url" {
  value       = var.enable_dashboard ? aws_lb.dashboard.dns_name : null
  description = "모니터링 대시보드 주소"
}
```

- 조건에 따라 출력값을 null 처리할 수 있음

---

## ✅ 정리

- `output` 블록은 **Terraform 실행 결과를 외부에 전달하거나 모듈 간 데이터를 연결**하는 데 사용됩니다.
- 민감한 정보는 `sensitive = true`로 안전하게 마스킹할 수 있으며,
- 조건 처리와 의존성 지정도 가능해 유연하게 활용 가능합니다.
- CI/CD 파이프라인, 모듈 재사용 시 필수적인 요소입니다.
