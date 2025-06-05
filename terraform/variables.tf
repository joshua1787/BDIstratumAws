variable "aws_region" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The name of the project, used for tagging resources."
  type        = string
  default     = "stratum"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "common_tags" {
  description = "Common tags to apply to all resources created by modules."
  type        = map(string)
  default = {
    Project     = "Stratum"
    Environment = "Dev"
  }
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "availability_zones" {
  description = "List of Availability Zones to use for subnets. Explicitly define these."
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "If true, create a single NAT Gateway."
  type        = bool
  default     = true
}

variable "db_instance_class" {
  description = "Instance class for the RDS database."
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version for RDS."
  type        = string
  default     = "15.7"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB for RDS."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "The name of the database to create in RDS."
  type        = string
  default     = "stratumdb"
}

variable "db_master_username_in_secret_key" {
  description = "The key name for the username within the Secrets Manager secret (e.g., 'username')."
  type        = string
  default     = "username"
}

variable "db_credentials_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret for DB credentials."
  type        = string
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS."
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "Skip final snapshot on RDS deletion."
  type        = bool
  default     = true
}

variable "temporary_db_access_cidrs" {
  description = "A list of temporary IP CIDRs (e.g., your IP/32) to allow direct DB access for setup."
  type        = list(string)
  default     = []
}

variable "eks_version" {
  description = "Desired Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.29"
}

variable "eks_node_instance_types" {
  description = "List of instance types for EKS worker nodes."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_size" {
  description = "Desired number of worker nodes in the EKS node group."
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of worker nodes in the EKS node group."
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of worker nodes in the EKS node group."
  type        = number
  default     = 3
}

variable "eks_cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks that can access the EKS public API endpoint."
  type        = list(string)
  default     = ["117.196.36.92/32"]
}

variable "eks_cluster_endpoint_private_access" {
  description = "Indicates whether the EKS private API server endpoint is enabled."
  type        = bool
  default     = true
}

variable "eks_cluster_endpoint_public_access" {
  description = "Indicates whether the EKS public API server endpoint is enabled."
  type        = bool
  default     = true
}