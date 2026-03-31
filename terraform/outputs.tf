output "training_bucket_name" {
  description = "S3 bucket for training data — upload train.csv here before triggering Autopilot"
  value       = aws_s3_bucket.training_data.bucket
}

output "artifacts_bucket_name" {
  description = "S3 bucket where Autopilot writes all candidate model artifacts"
  value       = aws_s3_bucket.model_artifacts.bucket
}

output "artifacts_bucket_uri" {
  description = "Full S3 URI for the Autopilot output path — used in the notebook"
  value       = local.artifacts_s3_uri
}

output "sagemaker_execution_role_arn" {
  description = "IAM role ARN — pass this to the Autopilot job config in the notebook"
  value       = aws_iam_role.sagemaker_execution.arn
}

output "notebook_instance_name" {
  description = "SageMaker notebook instance name — start this from the AWS console to begin the demo"
  value       = aws_sagemaker_notebook_instance.demo.name
}

output "model_package_group_name" {
  description = "Model registry group name — Autopilot registers candidates here after the experiment"
  value       = aws_sagemaker_model_package_group.demo.model_package_group_name
}

output "next_steps" {
  description = "What to do after terraform apply completes"
  value       = <<-EOT

    ── Phase 1 complete ──────────────────────────────────────────
    
    1. Upload training data:
       bash scripts/upload_training_data.sh

    2. Open the AWS console and start the notebook instance:
       ${aws_sagemaker_notebook_instance.demo.name}

    3. Open the notebook and follow the walkthrough:
       notebooks/autopilot_walkthrough.ipynb

    4. Once Autopilot completes and a model is approved,
       uncomment endpoint.tf and run terraform apply again.

    ─────────────────────────────────────────────────────────────

  EOT
}
