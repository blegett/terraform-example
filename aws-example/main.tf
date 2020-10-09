provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

module "data-replication-service" {
  source = "./data-replication-service"
  source-bucket = var.source-bucket
  destination-bucket = var.destination-bucket
}

module "data-load-dynamodb" {
  source = "./data-load-dynamodb"
  destination-bucket = var.destination-bucket
  dynamodb-table-name = var.dynamodb-table-name
  destination-bucket-arn = module.data-replication-service.destination-bucket-arn
  destination-bucket-id = module.data-replication-service.destination-bucket-id
}
