terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "us-east-1"
}

module "s3_bucket" {
  source = "./modules/s3"
  bucket_name = "upload-bucket-data-pipeline-234"
}

module "dynamodb_table" {
  source = "./modules/dynamodb"
  table_name = "dynamodb-table"
}

module "lambda_function" {
  source = "./modules/lambda"
  lambda_name        = "dynamodb_to_s3"
  handler_trigger     = "dynamodb_to_s3_trigger.lambda_handler"
  s3_bucket   = module.s3_bucket.bucket_name
  table_name  = module.dynamodb_table.table_name
  dynamodb_stream_arn = module.dynamodb_table.stream_arn
}

module "glue_catalog" {
  source         = "./modules/glue/glue_raw"
  database_name  = "catalog_db"
  table_name     = "catalog_json_table"
  s3_location    = "s3://${module.s3_bucket.bucket_name}/data/"
}

module "databrew" {
  source       = "./modules/databrew"
  glue_table   = module.glue_catalog.table_name
  glue_db      = module.glue_catalog.database_name
  s3_bucket_name    = module.s3_bucket.bucket_name
  data_zip     = module.lambda_function.data_zip
}

module "glue_catalog_cleaned" {
  source = "./modules/glue/glue_cleaned"
  database_name = "catalog_cleaned_db"
  table_name    = "catalog_cleaned_json_table"
  s3_location   = "s3://${module.s3_bucket.bucket_name}/cleaned/"
}

module "athena" {
  source = "./modules/athena"
  result_output_location = "s3://${module.s3_bucket.bucket_name}/athena-results/"
}
