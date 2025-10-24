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

variable "orleans_task_count" {
  description = "Desired number of Orleans silos (initial)"
  type        = number
  default     = 2
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "api_cpu"            { default = 256 }  # 0.25 vCPU
variable "api_memory"         { default = 512 }  # 512 MB
variable "orleans_cpu"        { default = 512 }
variable "orleans_memory"     { default = 1024 }