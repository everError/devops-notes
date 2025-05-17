data "archive_file" "dotfiles" {
  type        = "zip"
  output_path = "${path.module}/dotfiles.zip"
  source {
    content  = "hello a"
    filename = "${path.module}/a.txt"
  }
  source {
    content  = "hello b"
    filename = "${path.module}/b.txt"
  }
  source {
    content  = "hello c"
    filename = "${path.module}/c.txt"
  }
}
variable "names" {
  default = {
    a = "hello a"
    b = "hello b"
    c = "hello c"
  }
}
data "archive_file" "dotfiles_dynamic" {
  type        = "zip"
  output_path = "${path.module}/dotfiles_dynamic.zip"
  dynamic "source" {
    for_each = var.names
    content {
      content  = source.value
      filename = "${path.module}${source.key}.txt"
    }
  }
}