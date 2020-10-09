data "archive_file" "lambda-copy-dynamodb-zip" {
  type = "zip"
  source_file = "${path.module}/src/lambda-copy-data-to-dynamodb.py"
  output_path = "${path.module}/staging/lambda-copy-data-to-dynamodb.zip"
}

resource "aws_iam_role" "iam-lambda-copy-dynamodb" {
  name = "iam-lambda-copy-dynamodb"

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
  name = "s3_full_access_two"
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

resource "aws_iam_policy" "dynamodb-full-access-policy" {

  name = "dynamodb_full_access"
  description = "Gives Lambda full dynamodb access"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "dynamodb:*",
                "dax:*",
                "application-autoscaling:DeleteScalingPolicy",
                "application-autoscaling:DeregisterScalableTarget",
                "application-autoscaling:DescribeScalableTargets",
                "application-autoscaling:DescribeScalingActivities",
                "application-autoscaling:DescribeScalingPolicies",
                "application-autoscaling:PutScalingPolicy",
                "application-autoscaling:RegisterScalableTarget",
                "cloudwatch:DeleteAlarms",
                "cloudwatch:DescribeAlarmHistory",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:DescribeAlarmsForMetric",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:ListMetrics",
                "cloudwatch:PutMetricAlarm",
                "datapipeline:ActivatePipeline",
                "datapipeline:CreatePipeline",
                "datapipeline:DeletePipeline",
                "datapipeline:DescribeObjects",
                "datapipeline:DescribePipelines",
                "datapipeline:GetPipelineDefinition",
                "datapipeline:ListPipelines",
                "datapipeline:PutPipelineDefinition",
                "datapipeline:QueryObjects",
                "ec2:DescribeVpcs",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "iam:GetRole",
                "iam:ListRoles",
                "kms:DescribeKey",
                "kms:ListAliases",
                "sns:CreateTopic",
                "sns:DeleteTopic",
                "sns:ListSubscriptions",
                "sns:ListSubscriptionsByTopic",
                "sns:ListTopics",
                "sns:Subscribe",
                "sns:Unsubscribe",
                "sns:SetTopicAttributes",
                "lambda:CreateFunction",
                "lambda:ListFunctions",
                "lambda:ListEventSourceMappings",
                "lambda:CreateEventSourceMapping",
                "lambda:DeleteEventSourceMapping",
                "lambda:GetFunctionConfiguration",
                "lambda:DeleteFunction",
                "resource-groups:ListGroups",
                "resource-groups:ListGroupResources",
                "resource-groups:GetGroup",
                "resource-groups:GetGroupQuery",
                "resource-groups:DeleteGroup",
                "resource-groups:CreateGroup",
                "tag:GetResources"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": "cloudwatch:GetInsightRuleReport",
            "Effect": "Allow",
            "Resource": "arn:aws:cloudwatch:*:*:insight-rule/DynamoDBContributorInsights*"
        },
        {
            "Action": [
                "iam:PassRole"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "iam:PassedToService": [
                        "application-autoscaling.amazonaws.com",
                        "dax.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": [
                        "replication.dynamodb.amazonaws.com",
                        "dax.amazonaws.com",
                        "dynamodb.application-autoscaling.amazonaws.com",
                        "contributorinsights.dynamodb.amazonaws.com"
                    ]
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3-full-access-attach" {
  role       = aws_iam_role.iam-lambda-copy-dynamodb.name
  policy_arn = aws_iam_policy.s3-full-access-policy.arn
}

resource "aws_iam_role_policy_attachment" "dynamodb-full-access-attach" {
  role       = aws_iam_role.iam-lambda-copy-dynamodb.name
  policy_arn = aws_iam_policy.dynamodb-full-access-policy.arn
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-copy-dynamodb.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.destination-bucket-arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.destination-bucket-id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda-copy-dynamodb.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_lambda_function" "lambda-copy-dynamodb" {
    filename            = data.archive_file.lambda-copy-dynamodb-zip.output_path
    function_name       = "lambda-copy-data-to-dynamodb"
    role                = aws_iam_role.iam-lambda-copy-dynamodb.arn
    handler             = "lambda-copy-data-to-dynamodb.lambda_handler"
    source_code_hash    = filebase64sha256(data.archive_file.lambda-copy-dynamodb-zip.output_path)
    runtime             = var.runtime

    environment {
      variables = {
        destination_bucket_name = var.destination-bucket
      }
    }
}
