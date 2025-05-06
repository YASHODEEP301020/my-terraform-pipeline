data "archive_file" "src_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/src.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

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

resource "aws_iam_role_policy" "lambda_exec_policy" {
  name = "lambda_exec_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams"
        ],
        Resource = var.dynamodb_stream_arn
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${var.s3_bucket}",
          "arn:aws:s3:::${var.s3_bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_lambda_function" "dynamodb_to_s3_trigger" {
  function_name    = "${var.lambda_name}_trigger"
  role             = aws_iam_role.lambda_exec.arn
  handler          = var.handler_trigger
  runtime          = "python3.12"
  filename         = data.archive_file.src_zip.output_path
  source_code_hash = data.archive_file.src_zip.output_base64sha256
  environment {
    variables = {
      S3_BUCKET = var.s3_bucket
    }
  }
}

resource "aws_lambda_event_source_mapping" "trigger" {
  event_source_arn  = var.dynamodb_stream_arn
  function_name     = aws_lambda_function.dynamodb_to_s3_trigger.arn
  starting_position = "LATEST"
}
