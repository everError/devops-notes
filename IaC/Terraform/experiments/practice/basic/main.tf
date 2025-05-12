terraform {
  required_version = "> 1.0.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0.0"
    }
  }
  backend "local" {
    path = "state/teraform.tfstate"
  }
}

variable "file_name" {
  default = "abc.txt"
}

resource "local_file" "abc" {
  content  = "123456!"
  filename = "${path.module}/${var.file_name}"

  lifecycle {
    create_before_destroy = false # 기본값
    prevent_destroy       = false # 삭제 방지
    # ignore_changes = [ content ] # 변경사항 무시 # all 모든 병경 사항 무시
    precondition {
      condition     = var.file_name == "abc.txt"
      error_message = "file name is not \"abc.txt\""
    }
    postcondition {
      condition     = self.content != ""
      error_message = "content cannot empty"
    }
  }
}

# resource "local_file" "def" {
#   content  = local_file.abc.content
#   filename = "${path.module}/def.txt"
# }
resource "local_file" "def" {
  depends_on = [local_file.abc] # 명시적 종속성
  content    = "456!"
  filename   = "${path.module}/def.txt"
}

resource "local_file" "maybe" {
  count    = var.file_create ? 1 : 0
  content  = var.content
  filename = "maybe.txt"
}

variable "my_password" {
  default = "password"
  sensitive = true
}

variable "file_create" {
  type    = bool
  default = true
}

variable "content" {
  description = "파일이 생성되는 경우에 내용이 비어있는지 확인합니다."
  type        = string
  validation {
    condition     = var.file_create == true ? length(var.content) > 0 : true
    error_message = "파일 내용이 비어있을 수 없습니다."
  }
}