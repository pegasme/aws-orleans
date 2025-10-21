output "api_gateway_arn" {
  value       = aws_apigatewayv2_api.adventure_api.arn
  description = "Adventure Api Gateway ARN"
}

output "lambda_arn" {
  value       = aws_lambda_function.adventure_api.arn
  description = "Adventure Client Lamnda Function ARN"
}

output "ecs_instance_role_name" {
  value       = aws_iam_role.adventure_ecs_node_role.name
  description = "Adventure Client Lamnda Function ARN"
}