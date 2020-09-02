terraform {
  backend "s3" {
    bucket = "ms-age-of-name-infra"
    region = "us-east-1"
    key = "terraform.state"
  }
}
provider "aws" {
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
  pipeline_bucket_name = var.pipeline_bucket_name
  repo_branch          = var.repo_branch
  repo_name            = var.repo_name
  repo_owner           = var.repo_owner
}

module "react_pipeline_notifications" {
  source = "./sns"
}