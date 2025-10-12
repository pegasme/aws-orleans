variable "name" {
  type        = string
  description = "A name to associate with API Gateway."
}

variable "default_image_url" {
  type        = string
  description = "The URI of a container image in ECR."
}