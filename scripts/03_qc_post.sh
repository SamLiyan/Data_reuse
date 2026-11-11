#!/usr/bin/env bash
#SBATCH --job-name=qc_trim
#SBATCH --cpus-per-task=12
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --output=logs/%x_%j.out
# ---------------------------------------------------------------------------
# Step 3.  QC after trimming. Confirms adapters are gone and that you have not
#          thrown away most of the data.
#
#   in  : trimmed/*.fastq.gz
#   out : qc/trimmed/multiqc_report.html
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$SLURM_SUBMIT_DIR" 2>/dev/null || cd "$(dirname "$0")/.."

THREADS=${SLURM_CPUS_PER_TASK:-12}
mkdir -p qc/trimmed logs

fastqc -t "$THREADS" -o qc/trimmed trimmed/*.fastq.gz
multiqc -f -o qc/trimmed -n multiqc_report.html qc/trimmed

echo "[3] done -> qc/trimmed/multiqc_report.html"
