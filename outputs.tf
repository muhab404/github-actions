output "instance_public_ip" {
  value = aws_instance.github-actions-ec2.public_ip
}
