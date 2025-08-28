terraform {
  backend "s3" {
    bucket = "yasha1234"                   # your real S3 bucket name
    key    = "terraform/state.tfstate"     # path inside bucket
    region = "ap-south-1"
  }
}

