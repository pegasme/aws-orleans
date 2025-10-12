output "ecr_role_arn" {
  description = "ECR role ARN"
  value       = aws_iam_role.ecr_access_role.arn
}

output "repository_name" {
  description = "ECR Repository name"
  value       = aws_iam_role.aws_ecr_repository.name
}