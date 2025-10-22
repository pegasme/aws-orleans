variable "name" {
  type        = string
  description = "A name to associate with service."
}

variable "region" {
  description = "The region in which to create the resources."
  type        = string
  default     = "us-east-1"
}

variable "default_client_image_url" {
  type        = string
  description = "The URI of a container image in Lambda."
}

variable "default_server_image_url" {
  type        = string
  description = "The URI of a container image in ECS."
}

variable "vpc_id" {
  type        = string
  description = "Main VPC id"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs"
}

variable "dynamodb_table_arn" {
  type        = string
  description = "DynamoDB Table ARN for general storage"
}


variable "dynamodb_table_grain_arn" {
  type        = string
  description = "DynamoDB Table ARN for grain storage"
}