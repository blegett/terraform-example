resource "aws_dynamodb_table" "dynamodb-testing-table" {
    name = var.dynamodb-table-name
    billing_mode   = "PROVISIONED"
    read_capacity  = 1
    write_capacity = 1
    hash_key       = "id"

    attribute {
      name = "id"
      type = "S"
    }
}
