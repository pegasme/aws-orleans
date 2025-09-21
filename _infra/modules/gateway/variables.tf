variable "name" {
  type        = string
  description = "A name to associate with the gateway and its resources."
}

variable "vpc_id" {
  description = "VPC"
  type        = string
}