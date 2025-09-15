variable "project" {
  type    = string
  default = "cs1-ma-nca"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "cidr_hub" {
  type    = string
  default = "10.0.0.0/24"
}

variable "cidr_app" {
  type    = string
  default = "10.0.1.0/24"
}

variable "cidr_data" {
  type    = string
  default = "10.0.2.0/24"
}
