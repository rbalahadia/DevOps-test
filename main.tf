provider "aws"{
   region = var.region
   access_key = var.access_key
   secret_key = var.secret_key
}

terraform {
  backend "s3" {
    bucket = "tabist.devops.terraform.tfstate"
    key    = "tabist"
    region = "ap-southeast-1"
  }
}
#Creation of VPC
resource "aws_vpc" "Terraform_VPC"{
    cidr_block = var.VPC_CIDR_Block
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = " Tabist Terraform VPC"
        Description = " Tabist Teraform VPC"
        }

    }

resource "aws_iam_role" "Tabist_EC2_Role" {
  name = "Tabist_EC2_Role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com"
                ]
            }
        }
    ]
})
  inline_policy {
    name = "Tabist_EC2_Policy"

    policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "TabistEC2Policy",
            "Effect": "Allow",
            "Action": [
                "lambda:*",
                "ec2:*",
                "ssm:*",
                "s3:*",
                "ec2messages:*",
                "ssmmessages:*"
            ],
            "Resource": "*"
        }
    ]
   })
  }

  tags = {
    tag-key = "Tabist EC2 role"
  }
}

resource "aws_iam_instance_profile" "Tabist_instance_profile" {
  name = "Tabist_instance_profile"
  role = "${aws_iam_role.Tabist_EC2_Role.name}"
}

resource "aws_subnet" "Terraform_Public_Subnet_1a"{
    vpc_id = aws_vpc.Terraform_VPC.id
    cidr_block = var.public_subnet_cidr
    availability_zone = "ap-southeast-1a"
    tags = {
      "Name" = " Tabist Terraform Public Subnet 1a"
    }

}
resource "aws_subnet" "Terraform_Public_Subnet_1b"{
    vpc_id = aws_vpc.Terraform_VPC.id
    cidr_block = var.public_subnet_cidr2
    availability_zone = "ap-southeast-1b"
    tags = {
      "Name" = " Tabist Terraform Public Subnet 1b"
    }

}
#Public Subnet components
#Creation of Internet Gateway    
resource "aws_internet_gateway" "TerraformIG"{
    vpc_id = aws_vpc.Terraform_VPC.id

    tags = {
        Name = " Tabist TerraformIG"
        Description = " Tabist Terraform Internet gateway"
        }
    }   
resource "aws_route_table" "TerraformRT"{
    vpc_id = aws_vpc.Terraform_VPC.id
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TerraformIG.id
   }


    tags = {
      "Name" = " Tabist TerraformRT"
      "Description" = "Route table for Public Subnet"
    }

    
}
resource "aws_route_table_association" "TerraformRT_Association"{
    subnet_id      = aws_subnet.Terraform_Public_Subnet_1a.id
    route_table_id = aws_route_table.TerraformRT.id
}
resource "aws_route_table_association" "TerraformRT_Association_1b"{
    subnet_id      = aws_subnet.Terraform_Public_Subnet_1b.id
    route_table_id = aws_route_table.TerraformRT.id
}
#End of public subnet components
resource "aws_security_group" "Tabist_Security_group" {
  name        = "EC2 security group"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.Terraform_VPC.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.public_subnet_cidr, "49.144.200.29/32"]
  }
  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Tabist Ec2 Security group"
  }
}
resource "aws_instance" "tabist_EC2_1" {
  ami           = "ami-052f483c20fa1351a"
  instance_type = "t2.micro"
  availability_zone = "ap-southeast-1a"
  key_name = "TabistDevOpsTest"
  associate_public_ip_address = true
  subnet_id = aws_subnet.Terraform_Public_Subnet_1a.id
  vpc_security_group_ids = [aws_security_group.Tabist_Security_group.id]
  user_data_base64     = base64encode("${data.local_file.user_data_kafka.content}") 
  iam_instance_profile = "${aws_iam_instance_profile.Tabist_instance_profile.name}"
  metadata_options {
     http_tokens = "required"
     instance_metadata_tags = "enabled"
     http_endpoint = "enabled"
  }
  tags = {
    Name = "Tabist_EC2"
  }
  
}
resource "aws_instance" "tabist_EC2_2" {
  ami           = "ami-052f483c20fa1351a"
  instance_type = "t2.micro"
  availability_zone = "ap-southeast-1b"
  key_name = "TabistDevOpsTest"
  associate_public_ip_address = true
  subnet_id = aws_subnet.Terraform_Public_Subnet_1b.id
  vpc_security_group_ids = [aws_security_group.Tabist_Security_group.id]
  user_data_base64     = base64encode("${data.local_file.user_data_kafka.content}")
  iam_instance_profile = "${aws_iam_instance_profile.Tabist_instance_profile.name}"
  metadata_options {
     http_tokens = "required"
     instance_metadata_tags = "enabled"
     http_endpoint = "enabled"
  }
  tags = {
    Name = "Tabist_EC2_2"
  }
}
