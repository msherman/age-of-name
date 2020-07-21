resource "aws_s3_bucket" "pipeline-artifacts" {
  bucket = "ms-age-of-name-pipeline"
  acl    = "private"

  tags = {
    Name        = "pipeline bucket"
    Environment = "prod"
  }
}