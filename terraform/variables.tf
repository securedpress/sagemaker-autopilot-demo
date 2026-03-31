variable "aws_region" {
  description = "AWS region to deploy all resources"
  type        = string
  default     = "us-east-1"
}

variable "prefix" {
  description = "Prefix applied to all resource names — change this if deploying multiple instances"
  type        = string
  default     = "sagemaker-autopilot-demo"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.prefix))
    error_message = "Prefix must be lowercase alphanumeric with hyphens only — SageMaker and S3 naming rules."
  }
}

variable "owner_tag" {
  description = "Your name or team name — applied as an Owner tag on all resources"
  type        = string
  default     = "securedpress"
}

variable "autopilot_max_runtime_seconds" {
  description = "Maximum total runtime for the Autopilot job in seconds — default is 4 hours"
  type        = number
  default     = 14400

  validation {
    condition     = var.autopilot_max_runtime_seconds >= 3600 && var.autopilot_max_runtime_seconds <= 86400
    error_message = "Autopilot runtime must be between 1 hour (3600) and 24 hours (86400)."
  }
}

variable "endpoint_instance_type" {
  description = "SageMaker instance type for the real-time inference endpoint"
  type        = string
  default     = "ml.m5.xlarge"

  validation {
    condition     = can(regex("^ml\\.", var.endpoint_instance_type))
    error_message = "Must be a valid SageMaker instance type starting with ml."
  }
}
