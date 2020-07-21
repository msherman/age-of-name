resource "aws_codebuild_project" "react_build" {
  name         = "react-build"
  service_role = aws_iam_role.code_build_iam.arn
  artifacts {
    type                = "CODEPIPELINE"
    artifact_identifier = "react-artifacts"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type         = "LINUX_CONTAINER"
  }
  source {
    type            = "CODEPIPELINE"
    location        = "github_code"
  }
}