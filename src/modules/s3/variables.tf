variable "aws_region" {
    description = "AWS Region"
    type = string
    default = "us-east-1"
}

variable "bucket_name" {
    description = "Name of the bucket"
    type = string
    default = "cp-web-hosting-bucket"
}
