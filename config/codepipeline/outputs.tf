output "pipeline_bucket_arn" {
  value = aws_s3_bucket.pipeline-artifacts.arn
}

output "pipeline_arn" {
  value = aws_codepipeline.react_pipeline.arn
}