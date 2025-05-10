# 🧰 Terraform 기본 명령어 정리

Terraform은 선언형 구성 파일을 사용해 인프라를 자동으로 배포/관리하는 도구입니다. 아래는 Terraform 사용 시 가장 기본이 되는 명령어들의 설명과 예시입니다.

---

## 📌 1. `terraform init`

> 현재 작업 디렉토리를 Terraform 작업 환경으로 초기화합니다. 필요한 provider 플러그인을 다운로드합니다.

```bash
terraform init
```

- `.terraform/` 디렉토리 생성
- `.terraform.lock.hcl` 파일 생성

### 🔹 `-upgrade` 옵션

```bash
terraform init -upgrade
```

- 이미 설치된 provider 버전이 있더라도, `required_providers` 블록에 지정된 조건에 맞춰 **최신 버전으로 강제 업그레이드**합니다.
- `.terraform.lock.hcl` 파일도 갱신됩니다.
- 주로 provider 버전을 변경했거나, 최신 provider를 강제로 적용하고자 할 때 사용합니다.

### 🔹 `-reconfigure` 옵션

```bash
terraform init -reconfigure
```

- 기존의 backend 설정을 무시하고 **다시 초기화**합니다.
- 로컬 상태와 백엔드 상태 연결을 새로 구성할 때 사용됩니다.
- `.terraform` 내부 설정이 바뀌었거나 백엔드를 변경한 경우 사용

### 🔹 `-migrate-state` 옵션

```bash
terraform init -migrate-state
```

- 백엔드 구성이 변경된 경우, **기존 상태 파일(.tfstate)을 새로운 backend로 이동**시킵니다.
- 보통 `-reconfigure`와 함께 사용됨
- 수동으로 상태를 옮기지 않고도 안전하게 상태를 마이그레이션 가능

---

## 📌 2. `terraform plan`

> 구성 파일에 정의된 변경 사항을 실행하지 않고 미리 확인할 수 있습니다.

```bash
terraform plan
```

- 실제 리소스 변경 전 사전 시뮬레이션
- 변경, 생성, 삭제될 리소스를 미리 확인 가능

---

## 📌 3. `terraform apply`

> 구성 파일을 기반으로 실제 인프라를 생성/변경합니다.

```bash
terraform apply
```

- `terraform plan` 단계에서 보여준 변경 사항을 적용
- 사용자 입력 없이 자동 적용하려면 `-auto-approve` 옵션 사용

```bash
terraform apply -auto-approve
```

---

## 📌 4. `terraform destroy`

> Terraform으로 생성한 모든 리소스를 삭제합니다.

```bash
terraform destroy
```

- 사용자 입력 없이 자동 삭제하려면 `-auto-approve` 옵션 사용

---

## 📌 5. `terraform validate`

> `.tf` 파일의 문법 및 구성 오류를 확인합니다.

```bash
terraform validate
```

---

## 📌 6. `terraform fmt`

> 코드 스타일을 자동으로 정리해줍니다.

```bash
terraform fmt
```

---

## 📌 7. `terraform output`

> `output` 블록에 정의한 값을 조회합니다.

```bash
terraform output
```

- 개별 출력 값 확인:

```bash
terraform output <key>
```

---

## 📌 8. `terraform state`

> 현재 상태파일(`terraform.tfstate`)을 조회하거나 수정할 수 있는 명령어입니다.

```bash
terraform state list      # 관리 중인 리소스 목록 보기
terraform state show ...  # 특정 리소스 상태 보기
```

---

## 📌 9. `terraform taint` (Terraform v1.0 이하)

> 리소스를 강제로 다시 생성하도록 표시합니다. (v1.1 이상에서는 `terraform apply -replace` 사용 권장)

```bash
terraform taint aws_instance.my_instance
```

---

## 📌 10. `terraform graph`

> 리소스 간의 의존성 그래프를 생성합니다.

```bash
terraform graph | dot -Tpng > graph.png
```

- `Graphviz` 설치가 필요합니다.

---

## 📌 11. `terraform version`

> Terraform의 현재 버전을 확인합니다.

```bash
terraform version
```

---

## ✅ 명령어 요약 표

| 명령어               | 설명                       |
| -------------------- | -------------------------- |
| `terraform init`     | 작업 디렉토리 초기화       |
| `terraform plan`     | 변경 사항 미리 보기        |
| `terraform apply`    | 실제 리소스 생성/변경      |
| `terraform destroy`  | 리소스 삭제                |
| `terraform validate` | 구성 파일 문법 확인        |
| `terraform fmt`      | 코드 포맷 정리             |
| `terraform output`   | 출력 값 확인               |
| `terraform state`    | 상태 파일 정보 조회/수정   |
| `terraform graph`    | 리소스 간 의존 관계 시각화 |
| `terraform version`  | 버전 확인                  |

---

> Terraform을 효율적으로 사용하려면 `init → plan → apply → output` 흐름에 익숙해지는 것이 중요합니다.
