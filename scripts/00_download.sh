#!/usr/bin/env bash
#SBATCH --job-name=download
#SBATCH --cpus-per-task=6
#SBATCH --mem=16G
#SBATCH --time=12:00:00
#SBATCH --output=logs/%x_%j.out
# ---------------------------------------------------------------------------
# Step 0.  Fetch FASTQ for every run.
#
#   in  : data/accessions.txt   one SRR accession per line
#   out : raw/<SRR>_1.fastq.gz, raw/<SRR>_2.fastq.gz
#
# fasterq-dump needs scratch space roughly 10x the final gzipped size.
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$SLURM_SUBMIT_DIR" 2>/dev/null || cd "$(dirname "$0")/.."

ACC=data/accessions.txt
OUT=raw
TMP=${SCRATCH:-/tmp}/sra_tmp
THREADS=${SLURM_CPUS_PER_TASK:-6}

mkdir -p "$OUT" "$TMP" logs

while read -r srr; do
  [[ -z "$srr" || "$srr" == \#* ]] && continue
  if [[ -s "$OUT/${srr}_1.fastq.gz" ]]; then
    echo "[0] $srr already present, skipping"
    continue
  fi
  echo "[0] downloading $srr"
  prefetch --max-size 100G --output-directory "$TMP" "$srr"
  fasterq-dump "$TMP/$srr" --split-files --threads "$THREADS" \
               --temp "$TMP" --outdir "$OUT"
  pigz -p "$THREADS" "$OUT/${srr}"_*.fastq
  rm -rf "${TMP:?}/$srr"
done < "$ACC"

echo "[0] done -> $OUT/"
