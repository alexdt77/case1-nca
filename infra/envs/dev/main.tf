output "region" { value = var.aws_region }

data "aws_secretsmanager_secret" "db_pass" {
  name = "caselnca/db-pass"
}

resource "aws_secretsmanager_secret_version" "db_pass" {
  secret_id     = data.aws_secretsmanager_secret.db_pass.id
  secret_string = var.db_master_password
}

resource "aws_secretsmanager_secret_version" "db_pass" {
  secret_id     = aws_secretsmanager_secret.db_pass.id
  secret_string = var.db_master_password
}

