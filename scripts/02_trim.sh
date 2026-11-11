#!/usr/bin/env bash
#SBATCH --job-name=trim
#SBATCH --cpus-per-task=12
#SBATCH --mem=24G
#SBATCH --time=08:00:00
#SBATCH --output=logs/%x_%j.out
# ---------------------------------------------------------------------------
# Step 2.  Adapter and quality trimming with fastp.
#
#   in  : raw/<SRR>_1.fastq.gz, raw/<SRR>_2.fastq.gz
#   out : trimmed/<SRR>_1.fastq.gz, trimmed/<SRR>_2.fastq.gz
#         qc/fastp/<SRR>.json, qc/fastp/<SRR>.html
#
# Settings are deliberately conservative. Aggressive trimming shortens reads
# and short reads classify badly in step 6 - you lose specificity exactly where
# the question is. Minimum length 50 is the important one.
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$SLURM_SUBMIT_DIR" 2>/dev/null || cd "$(dirname "$0")/.."

THREADS=${SLURM_CPUS_PER_TASK:-12}
mkdir -p trimmed qc/fastp logs

for r1 in raw/*_1.fastq.gz; do
  srr=$(basename "$r1" _1.fastq.gz)
  r2="raw/${srr}_2.fastq.gz"
  [[ -s "trimmed/${srr}_1.fastq.gz" ]] && { echo "[2] $srr done, skipping"; continue; }
  echo "[2] trimming $srr"
  fastp \
    --in1 "$r1" --in2 "$r2" \
    --out1 "trimmed/${srr}_1.fastq.gz" --out2 "trimmed/${srr}_2.fastq.gz" \
    --detect_adapter_for_pe \
    --qualified_quality_phred 20 \
    --unqualified_percent_limit 30 \
    --n_base_limit 5 \
    --length_required 50 \
    --cut_front --cut_tail --cut_mean_quality 20 \
    --thread "$THREADS" \
    --json "qc/fastp/${srr}.json" \
    --html "qc/fastp/${srr}.html"
done

multiqc -f -o qc/fastp -n multiqc_fastp.html qc/fastp
echo "[2] done -> trimmed/"
