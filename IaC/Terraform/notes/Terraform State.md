# Terraform State 정리

## 📌 Terraform State란?

Terraform은 리소스의 실제 상태를 추적하고 관리하기 위해 **state 파일**을 사용합니다. 이 파일은 Terraform이 인프라 변경을 감지하고, 필요한 작업만 수행할 수 있게 합니다.

---

## 🔹 State의 역할

| 기능        | 설명                                                |
| ----------- | --------------------------------------------------- |
| 리소스 추적 | 생성된 리소스 및 속성 저장                          |
| 변경 감지   | 코드와 실제 인프라 상태를 비교해 필요한 변경만 수행 |
| 종속성 관리 | 리소스 간 의존성 추적 및 참조 관리                  |
| 협업 지원   | 원격 백엔드를 통한 상태 공유 및 동시 작업 방지      |

---

## 🔸 기본 동작

1. `terraform apply` 실행 시 리소스를 생성 또는 수정함
2. 해당 리소스 정보가 `terraform.tfstate` 파일에 저장됨
3. 이후 실행 시 이 파일을 기반으로 현재 상태와 코드 상태를 비교함

---

## 🔹 State 파일 구성

Terraform state 파일은 내부적으로 JSON 구조를 따르며, 다음과 같은 주요 필드들로 구성됩니다:

| 필드                | 설명                                           |
| ------------------- | ---------------------------------------------- |
| `version`           | state 파일 버전 정보                           |
| `terraform_version` | 이 state 파일을 생성한 Terraform 버전          |
| `serial`            | 변경 시마다 증가하는 시리얼 넘버 (버전 관리용) |
| `lineage`           | 동일한 상태 계보를 식별하는 UUID               |
| `resources`         | 생성된 모든 리소스의 목록 및 속성 정보         |

```json
{
  "version": 4,
  "terraform_version": "1.6.6",
  "serial": 12,
  "lineage": "eb5f9...",
  "resources": [
    {
      "type": "aws_instance",
      "name": "example",
      "instances": [
        {
          "attributes": {
            "id": "i-0abcdef1234567890",
            "ami": "ami-12345678",
            "instance_type": "t2.micro"
          }
        }
      ]
    }
  ]
}
```

---

## 🔄 State 동기화 (Sync)

Terraform은 상태 파일을 기준으로 다음 작업을 수행하며 동기화를 유지합니다:

1. **Plan 단계**: `terraform plan` 명령어 실행 시, 현재 상태(state)와 HCL 코드 정의를 비교하여 변경사항을 예측합니다.
2. **Apply 단계**: 실제로 리소스를 생성·수정한 후, 해당 결과를 다시 state 파일에 기록하여 상태를 최신으로 유지합니다.
3. **Refresh 단계**: `terraform refresh` 또는 `terraform plan` 내에서 상태를 실시간 인프라와 다시 동기화합니다.

> 🔁 이 동기화 덕분에 Terraform은 선언형 코드를 기준으로 항상 "무엇이 바뀌어야 하는가"만 판단하여 최소한의 작업만 수행할 수 있습니다.

---

## 🔸 주요 명령어

| 명령어                          | 설명                                       |
| ------------------------------- | ------------------------------------------ |
| `terraform show`                | 현재 state 파일의 상세 내용 출력           |
| `terraform state list`          | 관리 중인 리소스 목록 확인                 |
| `terraform state show <리소스>` | 특정 리소스의 상태 상세 출력               |
| `terraform state mv`            | 리소스의 이름 변경 (리팩토링용)            |
| `terraform state rm`            | 리소스를 state에서 제거 (실제 삭제는 아님) |
| `terraform import`              | 기존 리소스를 state에 추가 등록            |
| `terraform state pull`          | 현재 원격 state 파일을 로컬로 다운로드     |
| `terraform state push`          | 로컬 state 파일을 원격 백엔드에 업로드     |

---

## 🔹 백엔드 설정 예시 (S3)

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

> 💡 원격 상태 저장소를 사용하면 잠금(locking) 기능을 통해 동시 실행을 방지할 수 있으며, 팀 작업에 유리합니다.

---

## ⚠️ 주의사항

- `terraform.tfstate`에는 **민감한 정보**가 포함될 수 있으므로 Git 등의 버전관리 시스템에 절대 커밋 금지
- state 파일 직접 수정은 비추천 (정합성 문제 유발 가능)
- 백업 필수: `terraform state pull > backup.tfstate`와 같이 백업 가능

---

## ✅ 요약

- Terraform은 선언형 코드와 실제 리소스 상태를 동기화하기 위해 state 파일을 사용함
- state 파일은 JSON 구조로 구성되며, 버전, lineage, 리소스 등의 필드를 포함함
- Plan → Apply → Refresh 흐름을 통해 상태 동기화가 유지됨
- 협업을 위해 백엔드(S3, Azure Blob 등) 구성 권장
- 상태를 안전하게 다루기 위한 명령어 및 전략 숙지 필요
