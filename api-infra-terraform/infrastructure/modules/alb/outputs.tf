output "load_balancer_arn" {
  description = "ARN of the application load balancer."
  value       = aws_lb.this.arn
}

output "load_balancer_dns_name" {
  description = "Public DNS name of the application load balancer."
  value       = aws_lb.this.dns_name
}

output "load_balancer_zone_id" {
  description = "Canonical hosted zone ID for a future Route 53 alias."
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the ECS IP target group."
  value       = aws_lb_target_group.api.arn
}

output "listener_arns" {
  description = "ARNs of all configured ALB listeners."
  value = concat(
    aws_lb_listener.http_forward[*].arn,
    aws_lb_listener.http_redirect[*].arn,
    aws_lb_listener.https[*].arn
  )
}
