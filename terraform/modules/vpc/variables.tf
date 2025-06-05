variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "project_name" {
  description = "Name of the project for tagging."
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
}

variable "availability_zones" {
  description = "A list of Availability Zones to use for subnets. Should match the number of subnets of each type."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets. Set to false if not needed."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "If true, create a single NAT Gateway. If false, create one NAT Gateway per AZ."
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources."
  type        = map(string)
  default     = {}
}