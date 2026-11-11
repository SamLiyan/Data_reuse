#!/usr/bin/env bash
#SBATCH --job-name=qc_raw
#SBATCH --cpus-per-task=12
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=logs/%x_%j.out
# ---------------------------------------------------------------------------
# Step 1.  QC before trimming.
#
#   in  : raw/*.fastq.gz
#   out : qc/raw/*_fastqc.html, qc/raw/multiqc_report.html
#
# Look at: per-base quality, adapter content, overrepresented sequences, and
# duplication. High duplication in a low-input library is expected; a spike of
# overrepresented sequence that BLASTs to something non-fish is a hint of what
# step 6 will find.
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$SLURM_SUBMIT_DIR" 2>/dev/null || cd "$(dirname "$0")/.."

THREADS=${SLURM_CPUS_PER_TASK:-12}
mkdir -p qc/raw logs

fastqc -t "$THREADS" -o qc/raw raw/*.fastq.gz
multiqc -f -o qc/raw -n multiqc_report.html qc/raw

echo "[1] done -> qc/raw/multiqc_report.html"
