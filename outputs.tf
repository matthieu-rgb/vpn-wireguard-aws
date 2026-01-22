output "vpn_server_public_ip" {
  description = "Public IP address of the WireGuard VPN server"
  value       = aws_eip.wireguard.public_ip
}

output "vpn_server_instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.wireguard.id
}

output "ssh_private_key" {
  description = "SSH private key to connect to the server (KEEP SECRET!)"
  value       = tls_private_key.vpn_ssh.private_key_pem
  sensitive   = true
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh -i vpn-key.pem ubuntu@${aws_eip.wireguard.public_ip}"
}

output "next_steps" {
  description = "Next steps to complete the setup"
  value       = <<-EOT
    
    ╔══════════════════════════════════════════════════════════════╗
    ║           WireGuard VPN Server Deployed Successfully!         ║
    ╚══════════════════════════════════════════════════════════════╝
    
    1 Server IP: ${aws_eip.wireguard.public_ip}
    2 Instance ID: ${aws_instance.wireguard.id}
    3 Region: eu-central-1 (Frankfurt)
    
    -- NEXT STEPS:
    
    -  Save SSH private key:
       terraform output -raw ssh_private_key > vpn-key.pem
       chmod 400 vpn-key.pem
    
    2️  Wait 2-3 minutes for WireGuard installation to complete
    
    3️  Connect via SSH:
       ssh -i vpn-key.pem ubuntu@${aws_eip.wireguard.public_ip}
    
    4️  Get server public key:
       sudo cat /etc/wireguard/server_public.key
    
    5️  Generate client keys on your Mac:
       wg genkey | tee client_private.key | wg pubkey > client_public.key
    
    6️  Add client to server (on EC2):
       sudo wg set wg0 peer CLIENT_PUBLIC_KEY allowed-ips 10.8.0.2/32
    
    7️  Create client config on your Mac (see documentation)
    
    -- Monitoring:
       - CloudWatch alarm set for 10 GB/day
       - Check: aws ec2 describe-instances --instance-ids ${aws_instance.wireguard.id}
    

    
    -- Stop instance when not in use:
       aws ec2 stop-instances --instance-ids ${aws_instance.wireguard.id}
    
    -->  Start instance:
       aws ec2 start-instances --instance-ids ${aws_instance.wireguard.id}
    
  EOT
}
