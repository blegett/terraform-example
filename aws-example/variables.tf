variable "region" {
  description = "Region that resources are being deployed to"
  default = "us-east-1"
}

variable "access_key" {
  description = "Access Key for account"
  default = [YOUR_ACCESS_KEY]
}

variable "secret_key" {
  description = "Secret Key for account"
  default = [YOUR_SECRET_KEY]
}

variable "source-bucket" {
  type = string
}

variable "destination-bucket" {
  type = string
}

variable "dynamodb-table-name" {
  type = string
}
