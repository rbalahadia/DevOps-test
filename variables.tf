variable "region" {
    default = "ap-southeast-1"
}
variable "access_key"{
    default = "{secrets.access_key}"
}
variable "secret_key"{
    default = "{secrets.secret_key}"
}
variable "VPC_CIDR_Block"{
    default = "10.0.0.0/16"
}
variable "public_subnet_cidr"{
    default = "10.0.0.0/24"
}
variable "public_subnet_cidr2"{
    default = "10.0.2.0/24"
}
variable "private_subnet_cidr"{
    default = "10.0.1.0/24"
}
