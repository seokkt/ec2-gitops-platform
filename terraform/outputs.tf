output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "jenkins_public_ip" {
  description = "Jenkins Elastic IP"
  value       = aws_eip.jenkins.public_ip
}

output "k3s_public_ip" {
  description = "k3s Elastic IP"
  value       = aws_eip.k3s.public_ip
}

output "jenkins_ssh_command" {
  description = "SSH command for Jenkins"

  value = "ssh -i ~/.ssh/ec2-gitops ubuntu@${aws_eip.jenkins.public_ip}"
}

output "k3s_ssh_command" {
  description = "SSH command for k3s"

  value = "ssh -i ~/.ssh/ec2-gitops ubuntu@${aws_eip.k3s.public_ip}"
}