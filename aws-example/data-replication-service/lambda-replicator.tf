data "archive_file" "lambda-replicator-zip" {
  type = "zip"
  source_file = "${path.module}/src/lambda-replicator.py"
  output_path = "${path.module}/staging/lambda-replicator.zip"
}

resource "aws_iam_role" "iam_for_lambda_replicator" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "s3-full-access-policy" {
  name = "s3_full_access"
  description = "Gives Lambda full s3 access"

  policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": "s3:*",
              "Resource": "*"
          }
      ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "s3-full-access-attach" {
  role       = aws_iam_role.iam_for_lambda_replicator.name
  policy_arn = aws_iam_policy.s3-full-access-policy.arn
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-replicator.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source-bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.source-bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda-replicator.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_lambda_function" "lambda-replicator" {
    filename            = data.archive_file.lambda-replicator-zip.output_path
    function_name       = "lambda-replicator"
    role                = aws_iam_role.iam_for_lambda_replicator.arn
    handler             = "lambda-replicator.lambda_handler"
    source_code_hash    = filebase64sha256(data.archive_file.lambda-replicator-zip.output_path)
    runtime             = var.runtime

    environment {
      variables = {
        destination_bucket_name = var.destination-bucket
      }
    }
}
