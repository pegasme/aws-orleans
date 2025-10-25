variable "region" {
  description = "The region in which to create the resources."
  type        = string
  default     = "us-east-1"
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