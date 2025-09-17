resource "aws_ecr_repository" "api" {
  name         = "case1nca-api"
  force_delete = true
  image_scanning_configuration { scan_on_push = true }
}

output "ecr_repo_url" { value = aws_ecr_repository.api.repository_url }
