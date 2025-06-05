# outputs.tf - Outputs exposed by the ECR module

output "ecr_repository_url" {
  description = "The URL of the created ECR repository."
  value       = aws_ecr_repository.stratum_backend_repo.repository_url
}

output "ecr_repository_arn" {
  description = "The ARN of the created ECR repository."
  value       = aws_ecr_repository.stratum_backend_repo.arn
}