output "load_balancer_url" {
  description = "Click this URL to see your running containers!"
  value       = "http://${aws_lb.ecs_alb.dns_name}"
}