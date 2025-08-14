terraform {
  backend "s3" {
    bucket = "serverless-data-pipeline-backend-bucket-yashodeep-2025"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}


