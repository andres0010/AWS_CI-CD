variable "aws_region" {
    description = "AWS Region"
    type = string
    default = "eu-central-1"
}

variable "bucket_name" {
    description = "Name of the bucket"
    type = string
    default = "cp-web-hosting-bucket-prueba"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-west-1a", "us-west-1b"]
}
