variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "ec2-gitops"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.20.1.0/24"
}

variable "admin_cidr" {
  description = "Administrator public IP in CIDR notation"

  type = string

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be a valid CIDR block."
  }
}

variable "public_key_path" {
  description = "Path to the public SSH key"
  type        = string
  default     = "~/.ssh/ec2-gitops.pub"
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.small"
}

variable "k3s_instance_type" {
  description = "EC2 instance type for k3s"
  type        = string
  default     = "t3.small"
}

variable "jenkins_root_volume_size" {
  description = "Jenkins root EBS volume size in GiB"
  type        = number
  default     = 30
}

variable "k3s_root_volume_size" {
  description = "k3s root EBS volume size in GiB"
  type        = number
  default     = 40
}