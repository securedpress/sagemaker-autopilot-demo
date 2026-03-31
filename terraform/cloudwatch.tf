# --- CloudWatch alarms ---
# these alarms monitor the endpoint once Phase 3 is deployed
# they are provisioned in Phase 1 so monitoring is ready the moment the endpoint goes live
#
# to view in the AWS console:
# CloudWatch → Alarms → search for var.prefix

resource "aws_cloudwatch_metric_alarm" "endpoint_5xx_errors" {
  alarm_name  = "${local.alarm_prefix}-5xx-errors"
  namespace   = "AWS/SageMaker"
  metric_name = "Invocation5XXErrors"

  dimensions = {
    EndpointName = local.endpoint_name
    VariantName  = "primary"
  }

  # alert after 5 errors in a 5-minute window — single failed request is noise,
  # 5 in a row is a real problem worth waking someone up for
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_description = "Endpoint ${local.endpoint_name} is returning 5XX errors — model serving may be unhealthy"
}

resource "aws_cloudwatch_metric_alarm" "endpoint_latency_p99" {
  alarm_name  = "${local.alarm_prefix}-latency-p99"
  namespace   = "AWS/SageMaker"
  metric_name = "ModelLatency"

  dimensions = {
    EndpointName = local.endpoint_name
    VariantName  = "primary"
  }

  # p99 over 2 seconds on an ml.m5.xlarge running XGBoost inference is a red flag
  # typical healthy latency for this model should be under 100ms
  extended_statistic  = "p99"
  period              = 300
  evaluation_periods  = 2
  threshold           = 2000000  # microseconds — SageMaker reports ModelLatency in microseconds
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_description = "Endpoint ${local.endpoint_name} p99 latency is above 2s — check instance health or request volume"
}
