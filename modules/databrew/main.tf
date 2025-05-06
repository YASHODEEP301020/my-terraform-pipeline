data "aws_caller_identity" "current" {}

resource "aws_iam_role" "databrew_role" {
  name = "DataBrewAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "databrew.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "databrew_policy" {
  name = "DataBrewAccessPolicy"
  role = aws_iam_role.databrew_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = [
          "glue:GetTable",
          "glue:GetTableVersion",
          "glue:GetTableVersions",
          "glue:GetPartitions",
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_role" {
  name = "LambdaAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "databrew_trigger_policy" {
  name = "LambdaDatabrewPolicy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "databrew:StartJobRun",
          "glue:GetTable",
          "glue:GetTableVersion",
          "glue:GetTableVersions",
          "glue:GetPartitions",
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudformation_stack" "databrew_recipe_stack" {
  name          = "databrew-recipe-stack"
  template_body = file("modules/databrew/databrew_recipe.yaml")
  capabilities  = ["CAPABILITY_NAMED_IAM"]
}

resource "awscc_databrew_dataset" "datasetC" {
  name = "datasetInput"

  input = {
    data_catalog_input_definition = {
      catalog_id   = data.aws_caller_identity.current.account_id
      database_name = var.glue_db
      table_name    = var.glue_table
    }
  }

  depends_on = [aws_cloudformation_stack.databrew_recipe_stack]
}

resource "awscc_databrew_project" "dedupe" {
  name         = "deduplication-project"
  recipe_name  = "my-databrew-recipe"
  dataset_name = awscc_databrew_dataset.datasetC.name
  role_arn     = aws_iam_role.databrew_role.arn

  depends_on = [awscc_databrew_dataset.datasetC]
}

resource "awscc_databrew_job" "dedupe_job" {
  name         = "deduplication-job"
  type         = "RECIPE"
  project_name = awscc_databrew_project.dedupe.name
  role_arn     = aws_iam_role.databrew_role.arn

  outputs = [{
    location = {
      bucket = var.s3_bucket_name
      key    = "cleaned/"
    }
    format = "JSON"
    overwrite = true
  }]
}

resource "aws_lambda_function" "databrew_trigger" {
  function_name = "databrew_realtime_trigger"
  role          = aws_iam_role.lambda_role.arn
  handler       = "databrew_trigger.lambda_handler"
  runtime       = "python3.12"
  filename      = var.data_zip.output_path
  source_code_hash = var.data_zip.output_base64sha256

  environment {
    variables = {
      DATABREW_JOB_NAME =  awscc_databrew_job.dedupe_job.name
    }
  }
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.databrew_trigger.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.s3_bucket_name}"
}

resource "aws_s3_bucket_notification" "trigger" {
  bucket = var.s3_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.databrew_trigger.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".json"
    filter_prefix       = "data/"
  }

  depends_on = [aws_lambda_function.databrew_trigger]
}

