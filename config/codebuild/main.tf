resource "aws_codebuild_project" "react_build" {
  name         = "react-build"
  service_role = aws_iam_role.code_build_iam.arn
  artifacts {
    type                = "S3"
    location            = var.bucket_name
    artifact_identifier = "react-artifacts"
    packaging           = "NONE"
    path                = "/"
    name                = "/" //If this name is not set the name above will be the key the files are put inside of in the s3 bucket
    encryption_disabled = true
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type         = "LINUX_CONTAINER"
  }
  source {
    type            = "GITHUB"
    git_clone_depth = 1
    location        = "https://github.com/msherman/age-of-name.git"
  }
}