terraform {
  required_version = ">=1.0.0"
}

provider "aws" {
  region  = "us-east-2"
  profile = "default"
}

variable "aws_region" {
  description = "The AWS region to create things in."
  //default     = "us-east-2"
  //aws_region  = "us-east-2"
}

variable "aws_profile" {
  description = "AWS profile"
}

# Security Group
variable "ingressports" {
  type    = list(number)
  default = [8080, 22]
}

resource "aws_security_group" "jenkins-sg" {
  name        = "Allow web traffic"
  description = "inbound ports for ssh and standard http and everything outbound"
  dynamic "ingress" {
    for_each = var.ingressports
    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name"      = "Jenkins-sg"
    "Terraform" = "true"
  }
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }


  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  owners = ["amazon"]

}

resource "aws_instance" "jenkins" {
  ami             = data.aws_ami.amazon-linux-2.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.jenkins-sg.name]
  key_name        = "manish-devops"
  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras install epel -y",
      "sudo yum update -y",
      "sudo yum install java-1.8.0 -y",
      "sudo yum remove java-1.7.0-openjdk -y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
      "sudo yum install jenkins -y",
      "sudo service jenkins start",
      "sudo chkconfig --add jenkins",
    ]
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("/Users/manishupadhyay/projects/sandbox/aws-manishdev-ops.pem")
  }
  tags = {
    "Name" = "Jenkins"
  }
}
