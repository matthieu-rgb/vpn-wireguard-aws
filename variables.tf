variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "wireguard_port" {
  description = "WireGuard listen port"
  type        = number
  default     = 51820
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpn_network" {
  description = "VPN internal network"
  type        = string
  default     = "10.8.0.0/24"
}