variable "name" {
  type        = string
  description = "name tag value"
}

variable "tags" {
  type        = map(any)
  description = "tags for the vpc module"
}

variable "iam_role_name" {
  type        = string
  description = "iam role name to attach to the instance profile"
}

variable "key_pair_name" {
  type        = string
  description = "keypair to utilize"

}

resource "aws_security_group" "ec2_sg" {
  name        = join("", [var.name, "-", "ec2-sg"])
  description = "Allow  traffic for http and ssh"
  vpc_id = "vpc-078ac0c382267e2ce"


  ingress {
    from_port   = 22
    to_port     = 22
    description = "allow secure shell"
    protocol    = "tcp"
    cidr_blocks = ["192.168.1.133/32"]
  }

  ingress {
    description = "allow port 9100"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["192.168.1.134/32"]
  }

  ingress {
    description = "allow port 8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["192.168.1.134/32"]
  }

  egress {
    description = "allow port 0"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.1.134/32"]
  }
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = join("", [var.name, "-", "iam-instance-profile"])
  role = var.iam_role_name
}

# below is the Data Sources block
data "aws_ami" "web_ami" {
	most_recent = true
	owners = ["amazon"]

  filter {
    name = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "web_server" {
 # ami                    = "ami-0b0dcb5067f052a63"
  ami = data.aws_ami.web_ami.id
  instance_type          = "t3.small"
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = "subnet-0bf434bbd3d16af31"
  user_data              = file("scripts/userdata.sh")
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
  tags                   = merge(var.tags, { Name = join("", [var.name, "-", "webserver"]) }, { Environment = var.name })

  # best practices as per checkov scanner
  # subnet id specified 

  monitoring    = true
  ebs_optimized = true
  root_block_device {
    encrypted = true
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
  }

}


  

