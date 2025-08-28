resource "aws_s3_bucket" "primary" {
  bucket = "my-app-storage-bucket-yash1234"
}

resource "aws_s3_bucket" "secondary" {
  bucket = "my-app-storage-bucket-logs"
}





