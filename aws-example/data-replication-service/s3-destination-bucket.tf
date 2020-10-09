resource "aws_s3_bucket" "destination-bucket" {
    bucket = var.destination-bucket
    acl = "private"
}
