output "eks_cluster_endpoint" {
  description = "Endpoint for your EKS Kubernetes API server."
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_ca_certificate" {
  description = "Base64 encoded certificate data required to communicate with your cluster."
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.main.name
}

output "eks_node_group_role_arn" {
  description = "ARN of the IAM role for the EKS worker nodes."
  value       = aws_iam_role.eks_nodes_role.arn
}

output "eks_nodes_security_group_id" {
  description = "ID of the security group for the EKS worker nodes."
  value       = aws_security_group.eks_nodes_sg.id # Outputting the SG we created
}

output "eks_cluster_security_group_id" {
  description = "ID of the EKS cluster's primary security group (created by EKS)."
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}
output "backend_service_account_role_arn" {
  description = "ARN of the IAM role for the backend Kubernetes Service Account."
  value       = aws_iam_role.backend_service_account_role.arn
}


output "aws_lb_controller_role_arn" {
  description = "ARN of the IAM role for the AWS Load Balancer Controller Service Account."
  value       = aws_iam_role.aws_lb_controller_role.arn
}