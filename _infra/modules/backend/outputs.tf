output "alb_dns_name" {
  description = "Public URL of the ECS API load balancer"
  value       = aws_lb.client_alb.dns_name
}