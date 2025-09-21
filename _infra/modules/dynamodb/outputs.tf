output "table_arn" {
  value       = aws_dynamodb_table.adventure-dynamodb-table.arn
  description = "DynamoDB ARN"
}