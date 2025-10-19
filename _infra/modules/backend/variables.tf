variable "name" {
  type        = string
  description = "A name to associate with service."
}

variable "default_image_url" {
  type        = string
  description = "The URI of a container image in ECR."
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/16"
}