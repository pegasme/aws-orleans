variable "name" {
  type        = string
  description = "A name to associate with the dynamodb and its resources."
}

variable "region" {
  description = "The region in which to create the resources."
  type        = string
}

variable "ecs_instance_role_name" {
  description = "The role that use EC2 template inside ECS cluster."
  type        = string
}