terraform {
  backend "s3" {
    bucket = "ms-age-of-name-infra"
    region = "us-east-1"
    key    = "terraform.state"
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 2.0"
    }
  }
  required_version = ">= 0.13"
}
