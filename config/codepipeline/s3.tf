resource "aws_s3_bucket" "pipeline-artifacts" {
  bucket = var.pipeline_bucket_name
  acl    = "private"

  tags = {
    Name        = "pipeline bucket"
    Environment = "prod"
  }
}