variable "region" {
    default = "ap-southeast-1"
}
variable "VPC_CIDR_Block"{
    default = "10.0.0.0/16"
}
variable "public_subnet_cidr"{
    default = "10.0.0.0/24"
}
variable "private_subnet_cidr"{
    default = "10.0.1.0/24"
}