output "region" { value = var.aws_region }


data "aws_secretsmanager_secret" "db_pass" {
  name = "case1nca/db-pass"
}

data "aws_secretsmanager_secret_version" "db_pass" {
  secret_id = data.aws_secretsmanager_secret.db_pass.id
}
