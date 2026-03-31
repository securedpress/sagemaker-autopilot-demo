# Sagemaker Autopilot Demo

A fully deployable SageMaker Autopilot environment for fintech credit risk modeling.
Clone it, run `terraform apply`, and follow the notebook to train, evaluate, and deploy
a binary classification model that predicts cash advance repayment.

**Live demo dashboard →** [securedpress.github.io/sagemaker-autopilot-demo](https://securedpress.github.io/sagemaker-autopilot-demo)

---

## What this repo demonstrates

- End-to-end SageMaker Autopilot experiment on a real imbalanced dataset (88/12 split)
- Autopilot leaderboard evaluation across XGBoost, LightGBM, Linear Learner, MLP, and Random Forest
- SHAP feature importance analysis on the winning model
- Real-time inference endpoint deployed via Terraform
- CloudWatch monitoring wired from day one
- GitHub Pages dashboard updated with real experiment results

The dataset is synthetic but statistically realistic — modelled on cash advance repayment
behaviour using Plaid transaction features, internal repayment history, and user attributes.

---

## Architecture

<div align="center">
  <img src="docs/architecture.svg" alt="Architecture" />
</div>

---

Terraform provisions all AWS resources in a single apply. Training data flows from S3 into
a SageMaker Autopilot experiment that evaluates 250+ model candidates. The best model is
registered, deployed to a real-time endpoint, and monitored via CloudWatch. After the
experiment completes, `generate_dashboard.py` reads the results from S3 and publishes
the live dashboard to GitHub Pages.

---

## Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| AWS CLI | v2+ | Configured with `aws configure` |
| Terraform | >= 1.3.0 | [install guide](https://developer.hashicorp.com/terraform/install) |
| Python | 3.8+ | For scripts and notebook |
| boto3 | latest | `pip install boto3` |

**IAM permissions required** to run `terraform apply`:

```
AmazonSageMakerFullAccess
AmazonS3FullAccess
IAMFullAccess
CloudWatchFullAccess
```

> These are broad permissions intentionally — the same permissions
> a SageMaker audit would flag as over-provisioned in a production account.
> For a personal demo account this is acceptable.

---

## Deployment

### Phase 1 — Provision infrastructure

```bash
git clone https://github.com/securedpress/sagemaker-autopilot-demo.git
cd sagemaker-autopilot-demo

# configure your variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# edit terraform.tfvars — set owner_tag at minimum

cd terraform
terraform init
terraform apply
```

`terraform apply` provisions:

- S3 training data bucket + model artifacts bucket (versioned, encrypted, private)
- IAM execution role for SageMaker
- SageMaker notebook instance (`ml.t3.medium`)
- SageMaker Model Package Group (registry)
- CloudWatch alarms for endpoint errors and latency

**Estimated apply time:** 3–5 minutes.

After apply completes, upload the training data:

```bash
cd ..
bash scripts/upload_training_data.sh
```

---

### Phase 2 — Run the Autopilot experiment

1. Open the AWS console → SageMaker → Notebook instances
2. Start the `sagemaker-autopilot-demo-notebook` instance
3. Open JupyterLab and navigate to `autopilot_walkthrough.ipynb`
4. Run cells top to bottom through **Section 4 — Trigger Autopilot**

The Autopilot job runs in the background — **runtime is 2–4 hours**.
You can close the notebook and check back. Monitor progress in:

- The notebook poll cell (Section 4)
- AWS console → SageMaker → Autopilot → Jobs

When the job status shows `Completed`, continue through the notebook:

- **Section 5** — review the leaderboard
- **Section 6** — register the best model to the Model Registry
- **Section 7** — run SHAP feature importance analysis

> The notebook prints the `model_package_arn` you need for Phase 3.

---

### Phase 3 — Deploy the inference endpoint

Add the approved model ARN to your tfvars:

```hcl
# terraform/terraform.tfvars
model_package_arn = "arn:aws:sagemaker:us-east-1:123456789012:model-package/sagemaker-autopilot-demo-models/1"
```

Uncomment the three resource blocks in `terraform/endpoint.tf`, then apply:

```bash
cd terraform
terraform apply
```

**Estimated endpoint creation time:** 5–8 minutes.
**Running cost:** ~$0.23/hr (`ml.m5.xlarge`, `us-east-1`).

Run a live inference from the notebook — **Section 8**.

---

### Phase 4 — Update the dashboard

After the Autopilot job completes, regenerate the dashboard with real results:

```bash
pip install boto3
python scripts/generate_dashboard.py
```

The script reads the real leaderboard from SageMaker, updates
`dashboard/index.html` with actual AUC-ROC scores and candidate counts,
then prints the git commands to push to GitHub Pages:

```bash
git add dashboard/index.html
git commit -m "chore: update dashboard with real Autopilot results"
git push
```

GitHub Actions deploys automatically within ~30 seconds.

---

## Cleanup

Stop endpoint billing only (keeps model artifacts and Autopilot results):

```bash
terraform destroy -target aws_sagemaker_endpoint.demo
```

Full teardown — removes all AWS resources including S3 buckets:

```bash
terraform destroy
```

> `force_destroy = true` is set on both S3 buckets so `terraform destroy`
> completes cleanly even if buckets contain objects.
> Do not run full destroy if you want to keep your Autopilot results.

---

## Repository structure

```
sagemaker-autopilot-demo/
│
├── .github/workflows/
│   └── deploy-dashboard.yml     # deploys dashboard/ to GitHub Pages on push to main
│
├── dashboard/
│   └── index.html               # static demo dashboard — served via GitHub Pages
│
├── data/
│   └── train.csv                # synthetic fintech dataset (7K records, 18 features)
│
├── notebooks/
│   └── autopilot_walkthrough.ipynb  # guided experiment walkthrough
│
├── scripts/
│   ├── upload_training_data.sh  # uploads train.csv to S3 after terraform apply
│   └── generate_dashboard.py   # updates dashboard with real Autopilot results
│
└── terraform/
    ├── main.tf                  # provider, version constraints
    ├── variables.tf             # input variables with validation
    ├── locals.tf                # all resource names derived from prefix
    ├── iam.tf                   # SageMaker execution role
    ├── s3.tf                    # training + artifacts buckets
    ├── sagemaker.tf             # notebook, lifecycle config, model registry
    ├── endpoint.tf              # inference endpoint (Phase 3 — commented out)
    ├── cloudwatch.tf            # endpoint alarms
    ├── outputs.tf               # bucket names, role ARN, next steps
    └── terraform.tfvars.example # copy to terraform.tfvars and fill in
```

---

## Dataset

`data/train.csv` — 7,000 records, 18 features, binary target (`repaid`).

| Feature | Source | Description |
|---|---|---|
| `balance_advance_ratio` | Plaid | Account balance ÷ advance amount — top predictor |
| `prior_repay_score` | Internal DB | Historical repayment score (0–1) |
| `days_since_payroll` | Plaid | Days since last payroll deposit |
| `avg_monthly_income` | Plaid | 3-month rolling average income |
| `tx_velocity_30d` | Plaid | Debit transaction count last 30 days |
| `overdraft_frequency` | Internal DB | Historical overdraft count |
| `advance_amount` | Internal DB | Cash advance amount requested |
| `account_balance` | Plaid | Balance at time of request |
| `payroll_interval_days` | Plaid | Estimated payroll frequency |
| `days_until_payroll` | Plaid | Estimated days until next deposit |
| `neobank` | User attrs | Neobank status (Chime, Cash App, etc.) |
| `device_os` | User attrs | iOS / Android / Other |
| `institution_id` | User attrs | Bank institution identifier |
| `age` | User attrs | Applicant age |
| `months_as_customer` | Internal DB | Customer tenure |
| `prior_advance_count` | Internal DB | Number of prior advances |
| `last_repay_delay_days` | Internal DB | Repayment delay on last advance |
| `income_stability` | Plaid | Payroll deposit consistency (0–1) |

**Target:** `repaid` — 1 = repaid on time, 0 = default.
**Class split:** 88% repaid / 12% default. Autopilot handles SMOTE internally.

---

## Notes on IAM permissions

This demo uses `AmazonSageMakerFullAccess` and `AmazonS3FullAccess` for simplicity.
In a production environment these would be scoped to least-privilege custom policies.

If your SageMaker environment has over-permissioned roles, idle endpoints, or
unoptimised training jobs — a SecuredPress audit typically surfaces $30K–$80K
in annual waste within five business days.

---

## About SecuredPress

SecuredPress LLC delivers production-ready SageMaker Autopilot pipelines — infrastructure
as code, real-time endpoint deployment, CloudWatch monitoring, and SHAP reporting included.

**Services**

| Service | Price | Timeline |
|---|---|---|
| SageMaker Cost Audit | $2,500 | 5 business days |
| Cost + Security Audit | $4,000 | 5 business days |
| Secure Baseline Deployment | $8,000+ | Scoped engagement |
| Monthly Monitoring Retainer | $1,500/mo | 3-month minimum |

100% of the audit fee applies toward a deployment engagement if started within 60 days.

**Need this deployed in your environment? Book a free 15-minute scoping call →**
[calendly.com/jose-perez-securedpress/sagemaker-scoping](https://calendly.com/jose-perez-securedpress/sagemaker-scoping)
