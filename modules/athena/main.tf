resource "aws_athena_workgroup" "this" {
  name = "my-athena-workgroup"
  configuration {
    result_configuration {
      output_location = var.result_output_location
    }
  }
  force_destroy = true
}
