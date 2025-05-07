terraform {
  backend "s3" {
    bucket = "serverless-data-pipeline-backend-bucket"
    key    = "serverless-pipeline/dev/terraform.tfstate"
    region = "us-east-1"
  }
}
