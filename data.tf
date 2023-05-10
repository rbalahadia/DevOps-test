data "local_file" "user_data_kafka" {
  filename = "${path.module}/template/user_data.sh"
}