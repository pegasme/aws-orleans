output "api_gateway_arn" {
  value       = aws_apigatewayv2_api.adventure_api.arn
  description = "Adventure Api Gateway ARN"
}

output "lambda_arn" {
  value       = aws_lambda_function.adventure_api.arn
  description = "Adventure Client Lamnda Function ARN"
}