# --- notebook lifecycle config ---
# runs once when the notebook instance starts — installs dependencies
# and drops the demo notebook into the default working directory

resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "demo" {
  name = "${var.prefix}-lifecycle"

  on_start = base64encode(<<-SCRIPT
    #!/bin/bash
    set -e

    sudo -u ec2-user -i <<'EOF'
    pip install --quiet shap matplotlib seaborn pandas scikit-learn imbalanced-learn sagemaker --upgrade
    aws s3 cp s3://${aws_s3_bucket.training_data.bucket}/data/train.csv \
      /home/ec2-user/SageMaker/train.csv
    EOF
  SCRIPT
  )
}

# --- notebook instance ---

resource "aws_sagemaker_notebook_instance" "demo" {
  name          = "${var.prefix}-notebook"
  instance_type = "ml.t3.medium"
  role_arn      = aws_iam_role.sagemaker_execution.arn

  lifecycle_config_name = aws_sagemaker_notebook_instance_lifecycle_configuration.demo.name

  # notebooks are stopped by default — start manually from the AWS console
  # this avoids charges accumulating while the instance sits idle between demo sessions
  default_code_repository = null

  tags = {
    Purpose = "autopilot-demo-walkthrough"
  }
}

# --- model package group (registry) ---
# autopilot registers the best candidate here after the experiment completes
# the notebook references this group name when approving a model for deployment

resource "aws_sagemaker_model_package_group" "demo" {
  model_package_group_name        = local.model_package_group
  model_package_group_description = "Candidate models from the ${var.prefix} Autopilot experiment"
}
