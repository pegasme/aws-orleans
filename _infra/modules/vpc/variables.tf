variable "name" {
  type        = string
  description = "A name to associate with the VPC and its resources."
}

variable "region" {
  description = "The region in which to create the resources."
  type        = string
}
