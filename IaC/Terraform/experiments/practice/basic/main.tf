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
    prevent_destroy = false # 삭제 방지
    # ignore_changes = [ content ] # 변경사항 무시 # all 모든 병경 사항 무시
    precondition {
      condition = var.file_name == "abc.txt"
      error_message = "file name is not \"abc.txt\""
    }
    postcondition {
      condition = self.content != ""
      error_message = "content cannot empty"
    }
  }
}

# resource "local_file" "def" {
#   content  = local_file.abc.content
#   filename = "${path.module}/def.txt"
# }
resource "local_file" "def" {
  depends_on = [ local_file.abc ] # 명시적 종속성
  content  = "456!"
  filename = "${path.module}/def.txt"
}