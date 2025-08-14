variable "backend_bucket" {
  description = "S3 bucket name for storing Terraform state"
  type        = string
}

variable "backend_region" {
  description = "AWS region for the backend S3 bucket"
  type        = string
  default     = "ap-south-1"
}

