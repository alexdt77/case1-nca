provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project = var.project
      Env     = var.env
    }
  }
}

terraform {
  backend "s3" {}

  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  alias  = "notags"
  region = var.aws_region
}

# -------- Vars --------

variable "project" {
  description = "Projectnaam voor tagging"
  type        = string
  default     = "cs1-ma-nca"
}

variable "env" {
  description = "Omgeving (dev/test/prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner/Student"
  type        = string
  default     = "student"
}

variable "aws_region" {
  description = "AWS regio"
  type        = string
  default     = "eu-central-1"
}

# VPC
variable "cidr_app" {
  description = "CIDR voor de App VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# RDS
variable "db_engine" {
  description = "Databasetype"
  type        = string
  default     = "postgres"
}

variable "db_master_username" {
  description = "DB admin gebruiker"
  type        = string
  default     = "appadmin"
}

variable "db_master_password" {
  description = "DB admin wachtwoord (zet via TF_VAR_db_master_password of Secrets Manager)"
  type        = string
  sensitive   = true
}

# ECR
variable "ecr_repo_name" {
  description = "Naam van de ECR repository"
  type        = string
  default     = "case1nca-api"
}

# Monitoring input
variable "vpc_id" {
  type = string
}
variable "subnet_id" {
  type = string
}
variable "my_ip_cidr" {
  type = string
}
