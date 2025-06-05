variable "project_name" {
  description = "Name of the project for tagging and naming resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region where the EKS cluster will be deployed."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster and nodes will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS worker nodes and control plane ENIs."
  type        = list(string)
}

variable "eks_cluster_name" {
  description = "Name for the EKS cluster."
  type        = string
  default     = "" # If empty, will be derived from project_name and environment
}

variable "eks_version" {
  description = "Desired Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.29" # Check AWS for latest supported versions
}

variable "eks_node_group_name" {
  description = "Name for the EKS managed node group."
  type        = string
  default     = "" # If empty, will be derived
}

variable "eks_node_instance_types" {
  description = "List of instance types for EKS worker nodes."
  type        = list(string)
  default     = ["t3.medium"] # t3.medium is a common general-purpose choice
}

variable "eks_node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}

variable "common_tags" {
  description = "Common tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "eks_cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks that can access the EKS public endpoint. Use with caution."
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Allows access from anywhere. Restrict this in production.
}

variable "eks_cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled."
  type        = bool
  default     = true
}

variable "eks_cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled."
  type        = bool
  default     = true # Set to false for fully private clusters
}

variable "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing RDS credentials."
  type        = string
}