locals {
  # S3 bucket names
  training_bucket  = "${var.prefix}-training-data"
  artifacts_bucket = "${var.prefix}-model-artifacts"

  # IAM
  role_name = "${var.prefix}-sagemaker-execution"

  # SageMaker
  autopilot_job_name    = "${var.prefix}-job"
  model_package_group   = "${var.prefix}-models"
  endpoint_config_name  = "${var.prefix}-endpoint-config"
  endpoint_name         = "${var.prefix}-endpoint"

  # S3 key paths
  training_data_s3_uri  = "s3://${local.training_bucket}/data/train.csv"
  artifacts_s3_uri      = "s3://${local.artifacts_bucket}/autopilot/"

  # CloudWatch
  alarm_prefix = "${var.prefix}-alarm"

  # Target column — the binary repayment outcome in train.csv
  target_attribute = "repaid"
}
