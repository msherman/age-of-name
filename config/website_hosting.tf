resource "aws_s3_bucket" "age-of-name" {
  bucket = var.website_bucket_name
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
  tags   = {
    Name        = "Application bucket"
    Environment = "prod"
  }
}

resource "aws_s3_bucket_policy" "age-of-name-policy" {
  bucket = aws_s3_bucket.age-of-name.bucket
  policy = <<POLICY
{
  "Id": "Policy1594866894745",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1594866889422",
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.age-of-name.bucket}/*",
      "Principal": "*"
    }
  ]
}
  POLICY
}