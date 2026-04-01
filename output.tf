output "vpc_id" {
  value       = aws_vpc.techcorp.id
  description = "VPC ID"
}

output "alb_dns_name" {
  value       = aws_lb.techcorp.dns_name
  description = "Application Load Balancer DNS name (access the web app here)"
}

output "bastion_public_ip" {
  value       = aws_eip.bastion.public_ip
  description = "Bastion Host Public IP (use this to SSH)"
}

output "web_instance_ips" {
  value = {
    web1 = aws_instance.web1.private_ip
    web2 = aws_instance.web2.private_ip
  }
  description = "Private IP addresses of the Web servers"
}

output "db_instance_ip" {
  value       = aws_instance.db.private_ip
  description = "Private IP address of the Database server"
}