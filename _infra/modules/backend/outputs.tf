output "api_gateway_arn" {
  value       = aws_apigatewayv2_api.adventure_api.arn
  description = "Adventure Api Gateway ARN"
}

output "lambda_arn" {
  value       = aws_lambda_function.adventure_api.arn
  description = "Adventure Client Lamnda Function ARN"
}

output "api_gateway_url" {
  description = "Invoke URL of the HTTP API Gateway"
  value       = aws_apigatewayv2_stage.default.invoke_url
}