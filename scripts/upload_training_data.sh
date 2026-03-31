#!/bin/bash
set -euo pipefail

# upload_training_data.sh
# uploads train.csv to the S3 training bucket after terraform apply
# run this once before starting the notebook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TRAIN_CSV="$REPO_ROOT/data/train.csv"

# pull bucket name from terraform output — must be run from terraform directory
echo "Reading bucket name from terraform outputs..."
cd "$REPO_ROOT/terraform"

BUCKET=$(terraform output -raw training_bucket_name 2>/dev/null)

if [ -z "$BUCKET" ]; then
  echo ""
  echo "Error: could not read training_bucket_name from terraform outputs."
  echo "Make sure you have run terraform apply first."
  echo ""
  exit 1
fi

if [ ! -f "$TRAIN_CSV" ]; then
  echo ""
  echo "Error: train.csv not found at $TRAIN_CSV"
  echo ""
  exit 1
fi

echo "Uploading train.csv to s3://$BUCKET/data/train.csv ..."
aws s3 cp "$TRAIN_CSV" "s3://$BUCKET/data/train.csv"

echo ""
echo "Done. Training data is ready."
echo ""
echo "Next step: open the AWS console and start the notebook instance."
echo "Notebook: $(terraform output -raw notebook_instance_name)"
echo ""
