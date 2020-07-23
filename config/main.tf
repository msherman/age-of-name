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
  source              = "./codebuild"
  bucket_name         = aws_s3_bucket.ms-age-of-name.bucket
  s3_arn              = aws_s3_bucket.ms-age-of-name.arn
  pipeline_bucket_arn = module.react_code_pipeline.pipeline_bucket_arn
}

module "react_code_pipeline" {
  source                 = "./codepipeline"
  codebuild_project_name = module.react_code_build.codebuild_project_name
  website_bucket         = aws_s3_bucket.ms-age-of-name.bucket
  website_bucket_arn     = aws_s3_bucket.ms-age-of-name.arn
  sns_topic_arn          = module.react_pipeline_notifications.sns_topic_arn
}

module "react_pipeline_notifications" {
  source = "./sns"
}