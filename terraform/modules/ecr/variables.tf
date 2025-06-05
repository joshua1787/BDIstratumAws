# variables.tf - Input variables for the ECR module

variable "project_name" {
  description = "The name of the overall project, used for naming and tagging."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)."
  type        = string
}

variable "repository_name" {
  description = "The name for the ECR repository (e.g., stratum-backend)."
  type        = string
}

variable "service_name" {
  description = "The name of the service associated with this repository (e.g., backend)."
  type        = string
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository. Can be 'MUTABLE' or 'IMMUTABLE'."
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned for vulnerabilities on push."
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "A map of common tags to apply to the ECR repository."
  type        = map(string)
  default     = {}
}