resource "aws_instance" "ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = "vockey"  # Hardcoded to ensure it works in AWS Academy
  subnet_id              = aws_subnet.public-subnet1.id
  vpc_security_group_ids = [aws_security_group.security-group.id]
  
  # Uses the pre-existing Lab Role
  iam_instance_profile   = "LabInstanceProfile"

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  # Loads your shell script
  user_data = templatefile("./install-tools.sh", {})

  tags = {
    Name = var.instance_name
  }
}

