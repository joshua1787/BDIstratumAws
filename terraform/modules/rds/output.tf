output "db_instance_address" {
  description = "The address of the RDS instance."
  value       = aws_db_instance.main.address
}

output "db_instance_port" {
  description = "The port of the RDS instance."
  value       = aws_db_instance.main.port
}

output "db_instance_name" {
  description = "The name of the RDS instance."
  value       = aws_db_instance.main.db_name
}

output "db_instance_username" {
  description = "The master username for the RDS instance (from secret)."
  value       = aws_db_instance.main.username
}

output "db_security_group_id" {
  description = "The ID of the security group for the RDS instance."
  value       = aws_security_group.rds.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance."
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "The connection endpoint for the RDS instance."
  value       = aws_db_instance.main.endpoint
}