provider "aws" {
  region = var.aws_region
  access_key = "AKIA4HGXQP5G7TB4OKR5"
  secret_key = "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"
}

data "archive_file" "lambda_demo" {
  type = "zip"

  source_dir  = "${path.module}/nodejs"
  output_path = "${path.module}/nodejs.zip"
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "mylambdabucketforapigatewaysnodejs"

  force_destroy = true
}

resource "aws_s3_object" "lambda_demo" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "nodejs.zip"
  source = data.archive_file.lambda_demo.output_path

  etag = filemd5(data.archive_file.lambda_demo.output_path)
}

resource "aws_lambda_function" "lambda_demo" {
  function_name = "DemoLambdawithApiGateway1"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_demo.key

  runtime = "nodejs18.x"
  handler = "index.handler"
  source_code_hash = data.archive_file.lambda_demo.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "lambda_cloudwatch_log" {    
  name = "/aws/lambda/${aws_lambda_function.lambda_demo.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_api_gateway_rest_api" "api" {
  name = "myapitranslate"
endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "api" {
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = var.resource_path
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "api" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
}
#For Lambda integrations, you must use the HTTP method of POST for the integration request
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.api.id
  http_method             = aws_api_gateway_method.api.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_demo.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_demo.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.api.http_method}${aws_api_gateway_resource.api.path}"
}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  depends_on = [ aws_api_gateway_method.api, aws_api_gateway_integration.integration ]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.stage_name
}

