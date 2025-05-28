# Terraform Provisioners 정리

Terraform Provisioner는 인프라 리소스를 생성한 후 특정 작업(스크립트 실행 등)을 수행할 수 있도록 도와주는 기능입니다. 주로 초기화, 설정, 부트스트랩 등에 사용되며, 리소스 외부에서 실행되는 명령어를 통해 설정을 적용하거나 파일을 복사할 수 있습니다.

---

## 📌 사용 목적

- 인스턴스에 초기 설정 스크립트 실행
- 파일 복사
- 원격 서버에 패키지 설치
- 구성 완료 후 후속 작업 실행

> 단, 프로비저너는 가능하면 피하는 것이 권장됨 (불안정성과 재생성 이슈 때문)

---

## 🔧 프로비저너의 종류

### 1. `local-exec`

- **로컬 머신**에서 명령어를 실행
- 주요 속성:

  - `command`: 실행할 쉘 명령어 (string)
  - `working_dir`: (선택) 명령어 실행 디렉토리
  - `interpreter`: (선택) 명령어를 실행할 셸 지정 (예: `['PowerShell', '-Command']`)

- 예시:

```hcl
resource "aws_instance" "example" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  provisioner "local-exec" {
    command = "echo ${self.public_ip} > ip.txt"
  }
}
```

### 2. `remote-exec`

- \*\*원격 머신 (ex. EC2)\*\*에서 명령어 실행
- SSH 또는 WinRM을 사용하여 접속 필요
- 주요 속성:

  - `inline`: 여러 줄 명령어를 리스트로 나열
  - `script`: 로컬 스크립트 파일 경로 (한 개)
  - `scripts`: 여러 개의 로컬 스크립트 파일

- 예시:

```hcl
resource "aws_instance" "example" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y nginx"
    ]
  }
}
```

### 3. `file`

- 로컬에서 원격 서버로 **파일 복사**
- 주요 속성:

  - `source`: 로컬 파일 경로 (string)
  - `destination`: 원격 경로 (string)

- 예시:

```hcl
resource "aws_instance" "example" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "./app.conf"
    destination = "/etc/nginx/conf.d/app.conf"
  }
}
```

---

## ⚠️ 주의사항

- **재실행 불안정성**: `terraform apply` 시 동일 명령이 반복 실행될 수 있음
- **Idempotent 하지 않음**: 상태와 무관하게 실행될 수 있음
- **에러 발생 시 전체 리소스 생성을 중단할 수 있음**
- Terraform Cloud/Enterprise에서는 제한됨

---

## ✅ 대안

Terraform에서는 Provisioner를 가능하면 피하고, 다음과 같은 방법을 대신 사용할 것을 권장합니다:

### 1. **Packer**

- HashiCorp에서 제공하는 이미지 생성 도구
- AMI나 Docker 이미지 등 미리 구성된 머신 이미지를 빌드
- Terraform에서는 이 이미지를 바로 사용하므로 부트스트랩 단계 생략 가능
- 예: EC2에 필요한 패키지나 파일을 포함한 커스텀 AMI 생성

### 2. **Ansible / Chef / Puppet**

- 구성 관리(Configuration Management) 도구
- 선언형 구성으로 안정적이고 반복 가능한 방식으로 서버 상태 유지
- Terraform 이후 단계로 사용하여 인프라에 설정 적용
- 예: Ansible playbook으로 Nginx 설치 및 설정 적용

### 3. **cloud-init**

- EC2 인스턴스에서 제공하는 초기화 스크립트 실행 도구
- Terraform의 `user_data` 속성을 통해 cloud-init 스크립트 전달 가능
- 예:

```hcl
resource "aws_instance" "example" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y nginx
              systemctl start nginx
              EOF
}
```

### 4. **Startup Script (GCP)**

- GCP VM 인스턴스의 `metadata_startup_script`를 활용한 초기화 스크립트 실행
- cloud-init과 유사한 방식으로 설정 적용
- 예:

```hcl
resource "google_compute_instance" "example" {
  name         = "example-instance"
  machine_type = "e2-medium"

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt update
    apt install -y nginx
    systemctl start nginx
  EOT
}
```

Terraform에서는 프로비저너 대신 다음을 권장:

- Packer로 AMI 미리 구성
- Ansible/Chef/Puppet 등의 구성 관리 도구
- cloud-init 스크립트 사용 (EC2 user-data 등)
- Startup Script (GCP)

---

## 🔚 결론

Provisioner는 강력한 기능이지만 사용에 주의가 필요하며, 가능한 한 다른 방법으로 대체하는 것이 좋습니다. 꼭 사용해야 한다면 `create_before_destroy`, `depends_on`, `ignore_changes` 등의 설정을 조합하여 안정성을 높이는 것이 바람직합니다.
