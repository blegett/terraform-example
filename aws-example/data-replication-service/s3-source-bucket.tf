resource "aws_s3_bucket" "source-bucket" {
    bucket = var.source-bucket
    acl = "private"
}
