output "grain_table_arn" {
  value       = aws_dynamodb_table.grain_store.arn
  description = "Grain DynamoDB ARN"
}

output "cluster_table_arn" {
  value       = aws_dynamodb_table.cluster_store.arn
  description = "Cluster DynamoDB ARN"
}

output "grain_table_name" {
  value       = aws_dynamodb_table.grain_store.name
  description = "Grain DynamoDB Name"
}

output "cluster_table_name" {
  value       = aws_dynamodb_table.cluster_store.name
  description = "Cluster DynamoDB Name"
}