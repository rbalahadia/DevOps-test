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
    cidr_block = var.public_subnet_cidr
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


#Private Subnet
resource "aws_subnet" "Terraform_Private_Subnet"{
    vpc_id = aws_vpc.Terraform_VPC.id
    cidr_block = var.private_subnet_cidr
    availability_zone = "ap-southeast-1a"
    tags = {
      "Name" = "Tabist Terraform Private Subnet"
    }

}
#Private Subnet components
#Creation of NatGateway  
resource "aws_eip" "NATeip" {
  vpc      = true
}
resource "aws_nat_gateway" "TerraformNat"{
    allocation_id = aws_eip.NATeip.id
    subnet_id     = aws_subnet.Terraform_Private_Subnet.id
    depends_on = [aws_internet_gateway.TerraformIG]
    tags = {
        Name = "TerraformNat"
        Description = "Tabist Terraform Nat gateway"
        }
    }   
resource "aws_route_table" "TerraformPrivateRT"{
    vpc_id = aws_vpc.Terraform_VPC.id
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.TerraformNat.id
   }


    tags = {
      "Name" = "Tabist TerraformPrivateRT"
      "Description" = "Route table for Private Subnet"
    }

    
}
resource "aws_route_table_association" "TerraformNatRT_Association"{
    subnet_id      = aws_subnet.Terraform_Private_Subnet.id
    route_table_id = aws_route_table.TerraformPrivateRT.id
}

resource "aws_security_group" "Tabist_Security_group" {
  name        = "EC2 security group"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.Terraform_VPC.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.public_subnet_cidr]
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
  ami           = "ami-00b8d9cb8a7161e41"
  instance_type = "t2.micro"
  availability_zone = "ap-southeast-1a"
  key_name = "TabistDevOpsTest"
  subnet_id = aws_subnet.Terraform_Public_Subnet_1a.id
  vpc_security_group_ids = [aws_security_group.Tabist_Security_group.id]
  tags = {
    Name = "Tabist_EC2"
  }
}
resource "aws_instance" "tabist_EC2_2" {
  ami           = "ami-00b8d9cb8a7161e41"
  instance_type = "t2.micro"
  availability_zone = "ap-southeast-1b"
  key_name = "TabistDevOpsTest"
  subnet_id = aws_subnet.Terraform_Public_Subnet_1b.id
  vpc_security_group_ids = [aws_security_group.Tabist_Security_group.id]
  tags = {
    Name = "Tabist_EC2_2"
  }
}
