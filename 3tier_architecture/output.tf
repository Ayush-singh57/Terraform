output "website_url" {
  description = "The public URL to access your 3-tier application"
  value       = "http://${aws_lb.app_alb.dns_name}"
}