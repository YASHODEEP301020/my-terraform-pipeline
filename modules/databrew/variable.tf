variable "s3_bucket_name" {
  description = "S3 Bucket Name"
  type        = string
}

variable "data_zip" {}
variable "glue_table" {
  description = "Glue Catalog Table Name"
  type        = string
}
variable "glue_db" {
  description = "Glue Catalog Database Name"
  type        = string
}
