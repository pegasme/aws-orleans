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

variable "github_token" {
  description = "Guthub token."
  type        = string
  sensitive   = false # Good practice for secrets
}

variable "github_repo_url" {
  description = "GitHub Repo URL."
  type        = string
  sensitive   = false # Good practice for secrets
}