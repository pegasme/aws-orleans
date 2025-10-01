output "ecr_role_arn" {
  description = "ECR role ARN"
  value       = aws_iam_role.ecr_access_role.arn
}