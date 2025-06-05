# main.tf - Defines the ECR repository resource within the module

resource "aws_ecr_repository" "stratum_backend_repo" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.service_name}-ecr-repo"
    Application = "${var.project_name}-${var.service_name}"
    Environment = var.environment
    Service     = var.service_name
  })
}