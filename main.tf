terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"  # Francfort 
}

# Récupération de l'AMI Ubuntu 22.04 la plus récente
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Génération d'une clé SSH pour l'administration
resource "tls_private_key" "vpn_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Clé SSH dans AWS
resource "aws_key_pair" "vpn_key" {
  key_name   = "wireguard-vpn-key"
  public_key = tls_private_key.vpn_ssh.public_key_openssh
}

# Security Group - Firewall
resource "aws_security_group" "wireguard" {
  name        = "wireguard-vpn-sg"
  description = "Security group for WireGuard VPN server"

  # WireGuard UDP port
  ingress {
    description = "WireGuard VPN"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH - À RESTREINDRE avec votre IP publique
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # TODO: Remplacer par VOTRE_IP/32
  }

  # Tout le trafic sortant autorisé
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wireguard-vpn-sg"
  }
}

# Instance EC2 pour le serveur VPN
resource "aws_instance" "wireguard" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"  # Free Tier eligible
  key_name      = aws_key_pair.vpn_key.key_name

  vpc_security_group_ids = [aws_security_group.wireguard.id]

  # Script d'installation WireGuard
  user_data = file("${path.module}/wireguard-setup.sh")

  # Stockage
  root_block_device {
    volume_size = 8  # 8 GB suffisent
    volume_type = "gp3"
  }

  tags = {
    Name = "wireguard-vpn-server"
  }
}

# IP Élastique (fixe)
resource "aws_eip" "wireguard" {
  instance = aws_instance.wireguard.id
  domain   = "vpc"

  tags = {
    Name = "wireguard-vpn-eip"
  }
}

# CloudWatch alarm pour monitoring data transfer
resource "aws_cloudwatch_metric_alarm" "high_network_out" {
  alarm_name          = "wireguard-high-data-transfer"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = 86400  # 24 heures
  statistic           = "Sum"
  threshold           = 10737418240  # 10 GB en bytes
  alarm_description   = "Alert when daily data transfer exceeds 10 GB"
  alarm_actions       = []  # Vous pouvez ajouter un SNS topic ici

  dimensions = {
    InstanceId = aws_instance.wireguard.id
  }
}
