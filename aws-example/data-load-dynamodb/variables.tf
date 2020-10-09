variable "destination-bucket" {
  type = string
}

variable "dynamodb-table-name" {
  type = string
}

variable "runtime" {
  type = string
  default = "python3.8"
}

variable "destination-bucket-arn" {
  type = string
}

variable "destination-bucket-id" {
  type = string
}
