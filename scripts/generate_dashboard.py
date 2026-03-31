#!/usr/bin/env python3
"""
generate_dashboard.py

Reads real Autopilot experiment results from SageMaker and S3,
then rewrites dashboard/index.html with actual metrics.

Run this after Autopilot completes and before pushing to GitHub Pages.

Usage:
    python scripts/generate_dashboard.py

Requirements:
    pip install boto3
    AWS CLI configured with the same credentials used for terraform apply
"""

import json
import re
import subprocess
import sys
from pathlib import Path

try:
    import boto3
    from botocore.exceptions import ClientError
except ImportError:
    print("\nError: boto3 is not installed.")
    print("Run: pip install boto3\n")
    sys.exit(1)


REPO_ROOT = Path(__file__).parent.parent
DASHBOARD_HTML = REPO_ROOT / "dashboard" / "index.html"
TERRAFORM_DIR = REPO_ROOT / "terraform"


# ── helpers ──────────────────────────────────────────────────────────────────

def get_terraform_output(key):
    """Read a single value from terraform output."""
    try:
        result = subprocess.run(
            ["terraform", "output", "-raw", key],
            capture_output=True, text=True, check=True,
            cwd=TERRAFORM_DIR
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        print(f"\nError: could not read '{key}' from terraform outputs.")
        print("Make sure terraform apply has been run successfully.\n")
        sys.exit(1)


def get_autopilot_candidates(sm_client, job_name):
    """Return all candidates sorted by AUC-ROC descending."""
    candidates = []
    paginator = sm_client.get_paginator("list_candidates_for_auto_ml_job")

    for page in paginator.paginate(AutoMLJobName=job_name, SortBy="FinalObjectiveMetricValue",
                                   SortOrder="Descending"):
        candidates.extend(page["Candidates"])

    if not candidates:
        print(f"\nError: no candidates found for job '{job_name}'.")
        print("Make sure the Autopilot job has completed successfully.\n")
        sys.exit(1)

    return candidates


def extract_metrics(candidate):
    """Pull AUC-ROC and algorithm name from a candidate object."""
    name = candidate["CandidateName"]
    status = candidate["CandidateStatus"]
    auc = None

    for metric in candidate.get("FinalAutoMLJobObjectiveMetric", {}).get("MetricName", []):
        pass

    metric_obj = candidate.get("FinalAutoMLJobObjectiveMetric", {})
    if metric_obj:
        auc = round(metric_obj.get("Value", 0), 3)

    # infer algorithm family from candidate name — autopilot encodes it
    algo = "Unknown"
    name_lower = name.lower()
    if "xgboost" in name_lower:
        algo = "XGBoost"
    elif "lightgbm" in name_lower:
        algo = "LightGBM"
    elif "linear" in name_lower:
        algo = "Linear Learner"
    elif "mlp" in name_lower or "neural" in name_lower:
        algo = "Neural Network (MLP)"
    elif "randomforest" in name_lower or "random" in name_lower:
        algo = "Random Forest"
    elif "logistic" in name_lower:
        algo = "Logistic Regression"

    return {"name": name, "algo": algo, "auc": auc, "status": status}


def build_leaderboard_rows(candidates):
    """Build HTML table rows from candidate list."""
    rows = []
    baseline_auc = 0.874  # original model benchmark

    for i, c in enumerate(candidates[:6], start=1):
        m = extract_metrics(c)
        if m["auc"] is None:
            continue

        is_best = i == 1
        badge = '<span class="pill pill-best">BEST</span>' if is_best else ""
        color = "style=\"color:var(--green)\"" if is_best else ""
        auc_color = "style=\"color:var(--green)\"" if is_best else ""

        rows.append(f"""
          <tr>
            <td class="rank-num">{i:02d}</td>
            <td class="algo-name" {color}>{m['algo']}</td>
            <td class="metric-val" {auc_color}>{m['auc']}</td>
            <td class="metric-val">—</td>
            <td class="metric-val">—</td>
            <td class="metric-val">—</td>
            <td>{badge}</td>
          </tr>""")

    # always append baseline row
    rows.append(f"""
          <tr>
            <td class="rank-num">{len(rows) + 1:02d}</td>
            <td class="algo-name" style="color:var(--red)">Baseline (pre-Autopilot)</td>
            <td class="metric-val" style="color:var(--red)">{baseline_auc}</td>
            <td class="metric-val">—</td>
            <td class="metric-val">—</td>
            <td class="metric-val">—</td>
            <td><span class="pill pill-baseline">BASELINE</span></td>
          </tr>""")

    return "\n".join(rows)


def inject_into_html(html, placeholder, value):
    """Replace a clearly marked placeholder in the HTML."""
    marker = f"<!-- GENERATED:{placeholder} -->"
    if marker not in html:
        # placeholder not found — dashboard may not have been templated yet
        return html
    pattern = rf"{re.escape(marker)}.*?{re.escape(marker)}"
    replacement = f"{marker}{value}{marker}"
    return re.sub(pattern, replacement, html, flags=re.DOTALL)


# ── main ─────────────────────────────────────────────────────────────────────

def main():
    print("\nReading Terraform outputs...")
    region = get_terraform_output("training_bucket_name")  # use this to confirm state exists
    prefix = get_terraform_output("model_package_group_name").replace("-models", "")
    job_name = f"{prefix}-job"

    print(f"Autopilot job name: {job_name}")
    print(f"Region: us-east-1\n")

    sm_client = boto3.client("sagemaker", region_name="us-east-1")

    # verify job exists and is complete
    print("Checking Autopilot job status...")
    try:
        job = sm_client.describe_auto_ml_job(AutoMLJobName=job_name)
        status = job["AutoMLJobStatus"]
        print(f"Job status: {status}")

        if status != "Completed":
            print(f"\nAutopilot job is not complete yet (status: {status}).")
            print("Wait for the job to finish before running this script.\n")
            sys.exit(1)

    except ClientError as e:
        if e.response["Error"]["Code"] == "ResourceNotFound":
            print(f"\nError: Autopilot job '{job_name}' not found.")
            print("Trigger the job from the notebook first.\n")
        else:
            print(f"\nAWS error: {e}\n")
        sys.exit(1)

    # fetch leaderboard
    print("Fetching candidate leaderboard...")
    candidates = get_autopilot_candidates(sm_client, job_name)
    print(f"Found {len(candidates)} candidates.")

    best = extract_metrics(candidates[0])
    baseline_auc = 0.874
    improvement = round(((best["auc"] - baseline_auc) / baseline_auc) * 100, 1)

    print(f"\nBest model: {best['algo']} — AUC-ROC {best['auc']}")
    print(f"Baseline:   {baseline_auc}")
    print(f"Improvement: +{improvement}%\n")

    # read and update dashboard
    if not DASHBOARD_HTML.exists():
        print(f"Error: dashboard not found at {DASHBOARD_HTML}\n")
        sys.exit(1)

    print("Updating dashboard/index.html...")
    html = DASHBOARD_HTML.read_text()

    # inject best model stats into stat cards
    html = inject_into_html(html, "BEST_AUC", str(best["auc"]))
    html = inject_into_html(html, "BEST_ALGO", best["algo"])
    html = inject_into_html(html, "IMPROVEMENT", f"+{improvement}%")
    html = inject_into_html(html, "CANDIDATE_COUNT", str(len(candidates)))
    html = inject_into_html(html, "LEADERBOARD_ROWS", build_leaderboard_rows(candidates))

    DASHBOARD_HTML.write_text(html)
    print("Dashboard updated.\n")
    print("─" * 60)
    print("Next steps:")
    print("  git add dashboard/index.html")
    print("  git commit -m 'chore: update dashboard with real Autopilot results'")
    print("  git push")
    print("\nGitHub Actions will deploy to GitHub Pages automatically.")
    print("─" * 60 + "\n")


if __name__ == "__main__":
    main()
