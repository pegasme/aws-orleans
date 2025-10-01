variable "github_repo" {
  description = "GitHub repository in the format owner/repo"
  type        = string
}

variable "name" {
  description = "CodeDeploy application name"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}