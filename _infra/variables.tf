variable "region" {
  description = "The region in which to create the resources."
  type        = string
  default     = "us-east-1"
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "The AWS Secret Access Key."
  type        = string
  sensitive   = true # Good practice for secrets
}

variable "AWS_ACCESS_KEY_ID" {
  description = "The AWS Access Key."
  type        = string
  sensitive   = true # Good practice for secrets
}