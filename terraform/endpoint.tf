# --- PHASE 3 — uncomment after Autopilot completes and a model is approved ---
#
# before uncommenting:
#   1. Autopilot job must be complete (check AWS console or notebook)
#   2. A model must be approved in the model package group
#   3. Set model_package_arn below to the approved model ARN
#      find it with:
#      aws sagemaker list-model-packages \
#        --model-package-group-name <your-prefix>-models \
#        --model-approval-status Approved \
#        --query "ModelPackageSummaryList[0].ModelPackageArn" \
#        --output text
#
# then run: terraform apply
# estimated cost: ~$0.23/hr (ml.m5.xlarge, us-east-1)
# stop costs: terraform destroy -target aws_sagemaker_endpoint.demo

# variable "model_package_arn" {
#   description = "ARN of the approved model package to deploy — retrieved after Autopilot completes"
#   type        = string
# }

# resource "aws_sagemaker_model" "demo" {
#   name               = "${var.prefix}-model"
#   execution_role_arn = aws_iam_role.sagemaker_execution.arn
#
#   primary_container {
#     model_package_name = var.model_package_arn
#   }
# }

# resource "aws_sagemaker_endpoint_configuration" "demo" {
#   name = local.endpoint_config_name
#
#   production_variants {
#     variant_name           = "primary"
#     model_name             = aws_sagemaker_model.demo.name
#     initial_instance_count = 1
#     instance_type          = var.endpoint_instance_type
#
#     # capture 10% of requests and responses to S3 for monitoring
#     # sagemaker model monitor reads from this prefix
#     initial_variant_weight = 1.0
#   }
# }

# resource "aws_sagemaker_endpoint" "demo" {
#   name                 = local.endpoint_name
#   endpoint_config_name = aws_sagemaker_endpoint_configuration.demo.name
#
#   tags = {
#     Purpose = "autopilot-demo-inference"
#     Phase   = "3"
#   }
# }
