resource "aws_codepipeline" "react_pipeline" {
  name     = "react-pipeline"
  role_arn = aws_iam_role.react_pipeline.arn
  artifact_store {
    location = aws_s3_bucket.pipeline-artifacts.bucket
    type     = "S3"
  }

  //get the code from the repo
  stage {
    name = "Source"
    action {
      category         = "Source"
      name             = "GitHub"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["github_code"]

      configuration = {
        Owner  = "msherman"
        Repo   = "age-of-name"
        Branch = "master"
      }
    }
  }

  //get the code from the repo
  stage {
    name = "Build"
    action {
      category         = "Build"
      name             = "React-Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["github_code"]
      output_artifacts = ["react-artifacts"]

      configuration = {
        ProjectName = var.codebuild_project_name
      }
    }
  }
}