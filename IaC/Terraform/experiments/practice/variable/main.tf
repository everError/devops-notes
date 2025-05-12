variable "my_var" {
  # default가 없다면 입력 받음 (우선순위 1)
  default = "var2" # (우선순위 2)
}
resource "local_file" "abc" {
  content = var.my_var
  filename = "${path.module}/abc.txt"
}

# export TF_VAR_my_var=var3 환경 변수 선언시 (우선순위 3)
# terraform.tfvars 파일 (우선순위 4)
# *.auto.tfvars 파일 (우선순위 5)
# *.auto.tfvars.json (우선순위 6)
# terraform apply -var=my_var=var7 (우선순위 7)