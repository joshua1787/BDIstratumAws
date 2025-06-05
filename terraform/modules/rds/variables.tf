variable "project_name" {
  description = "Name of the project for tagging and naming resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "db_engine" {
  description = "Database engine (e.g., postgres, mysql)."
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "Database engine version."
  type        = string
  default     = "15.7"
}

variable "db_instance_class" {
  description = "Instance class for the RDS database."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "The name of the database to create."
  type        = string
  default     = "stratumdb"
}

variable "db_master_username_in_secret" {
  description = "The username key expected within the secret (e.g., 'username')."
  type        = string
  default     = "username"
}

variable "db_credentials_secret_arn" {
  description = "ARN of the AWS Secrets Manager secret containing the DB username and password."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the RDS instance will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group."
  type        = list(string)
}

variable "db_security_group_ingress_cidr_blocks" {
  description = "List of CIDR blocks allowed to connect to the DB."
  type        = list(string)
  default     = []
}

variable "db_security_group_ingress_source_sg_ids" {
  description = "A list of existing Security Group IDs that should be allowed to connect to the DB."
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted."
  type        = bool
  default     = true
}