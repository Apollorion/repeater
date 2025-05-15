variable "name" {
  type        = string
  description = "Name of the repeater"
}

variable "webhook_endpoint" {
  type        = string
  description = "Endpoint to repeat the request to"
}

variable "lambda_subnet_ids" {
  type        = list(string)
  description = "Subnets to put lambda function into"
}

variable "lambda_security_group_ids" {
  type        = list(string)
  description = "Security Groups to attach to lambda function"
}

variable "api_gateway_domain_name" {
  type        = string
  description = "api gateway domain name"
}

variable "acm_certificate_arn" {
  type        = string
  description = "acm certificate arn"
}

module "this" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.2.5"

  function_name = var.name
  description   = "A function the repeats webhook calls"
  handler       = "main.handler"
  runtime       = "python3.11"

  create_package         = false
  local_existing_package = "${path.module}/src/code.zip"

  publish = true
  timeout = 10

  cloudwatch_logs_retention_in_days = 30

  environment_variables = {
    WEBHOOK_ENDPOINT = var.webhook_endpoint
  }

  vpc_subnet_ids         = var.lambda_subnet_ids
  vpc_security_group_ids = var.lambda_security_group_ids
  attach_network_policy  = true

  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.default_apigatewayv2_stage_execution_arn}/*"
    }
  }
}

module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "4.0.0"

  name          = "webhook-repeater-${var.name}"
  description   = "webhook repeater lambda"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["*"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  create_default_stage_access_log_group            = true
  default_stage_access_log_group_name              = "/${var.name}"
  default_stage_access_log_format                  = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"
  default_stage_access_log_group_retention_in_days = 30

  # Custom domain
  domain_name                 = var.api_gateway_domain_name
  domain_name_certificate_arn = var.acm_certificate_arn

  # Routes and integrations
  integrations = {
    "POST /webhook" = {
      lambda_arn             = module.this.lambda_function_qualified_invoke_arn
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }
  }
}
