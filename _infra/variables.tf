variable "region" {
  description = "The region in which to create the resources."
  type        = string
  default    = "us-east-1"
}

variable "project-name" {
  description = "Project name will be prefix for all resources."
  type        = string
  default    = "adventure"
}