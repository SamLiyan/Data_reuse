#!/usr/bin/env bash
#SBATCH --job-name=kraken2
#SBATCH --cpus-per-task=16
#SBATCH --mem=100G
#SBATCH --time=08:00:00
#SBATCH --output=logs/%x_%j.out
# ---------------------------------------------------------------------------
# Step 6.  Classify the non-host reads.
#
#   in  : unmapped/<SRR>_{1,2}.fastq.gz
#   out : kraken/<SRR>.report      Kraken2 report (the full tree)
#         kraken/<SRR>.bracken     Bracken genus-level abundance
#
# Memory must exceed the database size - the standard Kraken2 database is
# ~70 GB, so 100 GB is the floor. --confidence 0.1 is a modest filter; raising
# it reduces false positives and loses sensitivity, and the choice changes the
# answer, so state whatever you use.
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$SLURM_SUBMIT_DIR" 2>/dev/null || cd "$(dirname "$0")/.."

THREADS=${SLURM_CPUS_PER_TASK:-16}
KDB=${KRAKEN2_DB:-db/kraken2_standard}
READLEN=150

mkdir -p kraken logs

[[ -d "$KDB" ]] || { echo "Kraken2 database not found at $KDB" >&2; exit 1; }

for r1 in unmapped/*_1.fastq.gz; do
  srr=$(basename "$r1" _1.fastq.gz)
  r2="unmapped/${srr}_2.fastq.gz"
  [[ -s "kraken/${srr}.bracken" ]] && { echo "[6] $srr done, skipping"; continue; }
  echo "[6] classifying $srr"

  kraken2 --db "$KDB" --threads "$THREADS" --paired \
          --confidence 0.1 \
          --report "kraken/${srr}.report" \
          --output /dev/null \
          "$r1" "$r2"

  bracken -d "$KDB" -i "kraken/${srr}.report" \
          -o "kraken/${srr}.bracken" \
          -r "$READLEN" -l G -t 10
done

echo "[6] done -> kraken/"
