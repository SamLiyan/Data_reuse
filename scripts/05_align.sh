#!/usr/bin/env bash
#SBATCH --job-name=align
#SBATCH --cpus-per-task=16
#SBATCH --mem=48G
#SBATCH --time=16:00:00
#SBATCH --output=logs/%x_%j.out
# ---------------------------------------------------------------------------
# Step 5.  Align to the host and split the result.
#
#   in  : trimmed/<SRR>_{1,2}.fastq.gz, ref/catfish.*.ht2
#   out : bam/<SRR>.host.bam             what mapped (the original experiment)
#         unmapped/<SRR>_{1,2}.fastq.gz  what did not (this study)
#         counts/<SRR>.align.txt         total / mapped / unmapped
#
# -f 12 -F 256 keeps pairs where BOTH mates failed to map, excluding secondary
# alignments. Requiring both mates is the conservative choice: a pair with one
# mate mapped to the host is most likely host.
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$SLURM_SUBMIT_DIR" 2>/dev/null || cd "$(dirname "$0")/.."

THREADS=${SLURM_CPUS_PER_TASK:-16}
mkdir -p bam unmapped counts logs

for r1 in trimmed/*_1.fastq.gz; do
  srr=$(basename "$r1" _1.fastq.gz)
  r2="trimmed/${srr}_2.fastq.gz"
  [[ -s "unmapped/${srr}_1.fastq.gz" ]] && { echo "[5] $srr done, skipping"; continue; }
  echo "[5] aligning $srr"

  hisat2 -p "$THREADS" -x ref/catfish \
         -1 "$r1" -2 "$r2" \
         --summary-file "counts/${srr}.hisat2.log" \
    | samtools sort -@ 4 -o "bam/${srr}.all.bam" -

  samtools index "bam/${srr}.all.bam"

  # host-mapped reads
  samtools view -@ 4 -b -F 4 "bam/${srr}.all.bam" > "bam/${srr}.host.bam"

  # pairs where both mates failed to map
  samtools view -@ 4 -b -f 12 -F 256 "bam/${srr}.all.bam" \
    | samtools sort -@ 4 -n -o "bam/${srr}.unmapped.bam" -

  samtools fastq -@ 4 \
    -1 "unmapped/${srr}_1.fastq.gz" \
    -2 "unmapped/${srr}_2.fastq.gz" \
    -0 /dev/null -s /dev/null -n "bam/${srr}.unmapped.bam"

  total=$(samtools view -@ 4 -c "bam/${srr}.all.bam")
  mapped=$(samtools view -@ 4 -c -F 4 "bam/${srr}.all.bam")
  unmapped=$(samtools view -@ 4 -c -f 12 -F 256 "bam/${srr}.all.bam")
  printf "%s\ttotal=%s\tmapped=%s\tunmapped_pairs=%s\n" \
         "$srr" "$total" "$mapped" "$unmapped" > "counts/${srr}.align.txt"

  rm -f "bam/${srr}.all.bam" "bam/${srr}.all.bam.bai" "bam/${srr}.unmapped.bam"
done

echo "[5] done -> unmapped/"
