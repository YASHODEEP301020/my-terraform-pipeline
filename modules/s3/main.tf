resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  force_destroy = true
}

resource "aws_s3_object" "sample_data" {
  bucket = aws_s3_bucket.this.id
  key    = "data/sample.json"
  source = "${path.module}/sample.json"
  content_type = "application/json"
}
