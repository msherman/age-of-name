provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "infra" {
  bucket = var.infra_bucket_name
  acl    = "private"

  tags = {
    Name        = "infra bucket"
    Description = "Holds state file for the main terraform code"
  }
}