variable "source-bucket" {
  type = string
}

variable "destination-bucket" {
  type = string
}

variable "runtime" {
  type = string
  default = "python3.8"
}
