resource "random_id" "suffix" {
  byte_length = 3
}

resource "aws_s3_bucket" "tf_test" {
  bucket        = "${var.project}-${var.env}-tf-test-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Project = var.project
    Env     = var.env
  }
}
