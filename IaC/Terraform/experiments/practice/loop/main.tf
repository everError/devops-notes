variable "names" {
  type    = list(string)
  default = ["a", "c"]
}
resource "local_file" "abc" {
  count    = length(var.names)
  content  = "abc"
  filename = "${path.module}/abc-${var.names[count.index]}.txt"
}
resource "local_file" "def" {
  count   = length(var.names)
  content = local_file.abc[count.index].content
  # element function - list형태의 목록에서 인덱스를 사용하여 단일 요소를 검색하는 함수
  filename = "${path.module}/def-${element(var.names, count.index)}.txt"
}
resource "local_file" "feach" {
  for_each = {
    a = "content_a"
    b = "content_b"
  }
  content  = each.value
  filename = "${path.module}/${each.key}.txt"
}
variable "names_f" {
  default = {
    a = "content a"
    b = "content b"
    c = "content c"
  }
}
resource "local_file" "f_abc" {
  for_each = var.names_f
  content  = each.value
  filename = "${path.module}/abc_f-${each.key}.txt"
}
resource "local_file" "f_def" {
  for_each = local_file.f_abc
  content  = each.value.content
  filename = "${path.module}/def_f-${each.key}.txt"
}
resource "local_file" "s_abc" {
  for_each = toset(["a", "b", "c"])
  content  = "abc"
  filename = "${path.module}/abc_s-${each.key}.txt"
}
resource "local_file" "for_abc" {
  content  = jsonencode([for s in var.names : upper(s)]) # jsonencode(var.names) jsonencode(["a", "b", "c"])
  filename = "${path.module}/abc_for.txt"
}