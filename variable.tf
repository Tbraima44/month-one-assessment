variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type_bastion" {
  description = "Instance type for Bastion host"
  type        = string
  default     = "t3.micro"
}

variable "instance_type_web" {
  description = "Instance type for Web servers"
  type        = string
  default     = "t3.micro"
}

variable "instance_type_db" {
  description = "Instance type for Database server"
  type        = string
  default     = "t3.small"
}

variable "key_pair_name" {
  description = "Name of the SSH key pair (optional - password auth also works)"
  type        = string
  default     = null
}

variable "my_ip" {
  description = "Your current public IP address (for Bastion SSH access) - use /32"
  type        = string
  # Example: "203.0.113.5/32"
}