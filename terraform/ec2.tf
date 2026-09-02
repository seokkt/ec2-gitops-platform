data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_key_pair" "project" {
  key_name = "${var.project_name}-key"

  public_key = file(
    pathexpand(var.public_key_path)
  )

  tags = {
    Name = "${var.project_name}-key"
  }
}

resource "aws_instance" "jenkins" {
  ami           = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = var.jenkins_instance_type

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.jenkins.id
  ]

  associate_public_ip_address = true

  key_name = aws_key_pair.project.key_name

  iam_instance_profile = aws_iam_instance_profile.jenkins.name

  user_data = file("${path.module}/user-data/jenkins.sh")

  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.jenkins_root_volume_size

    encrypted = true
  }

  tags = {
    Name = "${var.project_name}-jenkins"
    Role = "jenkins"
  }
}

resource "aws_instance" "k3s" {
  ami           = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = var.k3s_instance_type

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.k3s.id
  ]

  associate_public_ip_address = true

  key_name = aws_key_pair.project.key_name

  iam_instance_profile = aws_iam_instance_profile.k3s.name

  user_data = file("${path.module}/user-data/k3s.sh")

  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.k3s_root_volume_size

    encrypted = true
  }

  tags = {
    Name = "${var.project_name}-k3s"
    Role = "k3s"
  }
}

resource "aws_eip" "jenkins" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-jenkins-eip"
  }
}

resource "aws_eip_association" "jenkins" {
  instance_id   = aws_instance.jenkins.id
  allocation_id = aws_eip.jenkins.id
}

resource "aws_eip" "k3s" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-k3s-eip"
  }
}

resource "aws_eip_association" "k3s" {
  instance_id   = aws_instance.k3s.id
  allocation_id = aws_eip.k3s.id
}

