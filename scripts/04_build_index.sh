#!/usr/bin/env bash
#SBATCH --job-name=hisat2_index
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=08:00:00
#SBATCH --output=logs/%x_%j.out
# ---------------------------------------------------------------------------
# Step 4.  Build the host index. Run once.
#
#   out : ref/catfish.*.ht2
#
# NOTE: there is no widely used chromosome-level Ictalurus furcatus assembly,
# so this uses I. punctatus (channel catfish). Blue catfish reads from diverged
# regions will not align and will be counted as non-host downstream. Quantify
# that before trusting absolute percentages - one way is to align a known-clean
# blue catfish library and see what fraction fails to map.
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$SLURM_SUBMIT_DIR" 2>/dev/null || cd "$(dirname "$0")/.."

THREADS=${SLURM_CPUS_PER_TASK:-16}
mkdir -p ref logs

GENOME_URL="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/001/660/625/GCF_001660625.3_Coco_2.0/GCF_001660625.3_Coco_2.0_genomic.fna.gz"

if [[ ! -s ref/catfish.fa ]]; then
  echo "[4] fetching host genome"
  curl -L "$GENOME_URL" -o ref/catfish.fa.gz
  gunzip -c ref/catfish.fa.gz > ref/catfish.fa
fi

echo "[4] building HISAT2 index"
hisat2-build -p "$THREADS" ref/catfish.fa ref/catfish

echo "[4] done -> ref/catfish.*.ht2"
