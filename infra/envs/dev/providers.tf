provider "aws" {
  region = var.aws_region
  default_tags {
    tags = { Project = "case1-nca", Env = var.env }
  }
}
