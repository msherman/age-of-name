terraform {
  backend "s3" {
    bucket = "ms-age-of-name-infra"
    region = "us-east-1"
    key    = "terraform.state"
  }
}

# Configure the AWS Provider
provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

module "react_code_build" {
  source                = "./codebuild"
  bucket_name           = aws_s3_bucket.ms-age-of-me.bucket
  s3_arn                = aws_s3_bucket.ms-age-of-me.arn
}