#!/usr/bin/env bash
#SBATCH --job-name=summarise
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --output=logs/%x_%j.out
# ---------------------------------------------------------------------------
# Step 7.  Collapse the per-run output into the two tables the analysis reads.
#
#   in  : kraken/<SRR>.report, kraken/<SRR>.bracken, counts/<SRR>.align.txt
#   out : data/domain_summary.csv         testis runs
#         data/sperm_runs_taxonomy.csv    sperm runs, joined to male and treatment
#
# Kraken2 report columns: pct, clade_reads, direct_reads, rank, taxid, name.
# Domain totals are the clade_reads on the rows whose rank code is "D".
#
# After this, bash/02_analyse.sh and bash/03_report.sh run unchanged.
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$SLURM_SUBMIT_DIR" 2>/dev/null || cd "$(dirname "$0")/.."

mkdir -p data logs
OUT=data/raw_pipeline_composition.csv

echo "run,analysed,pct_bacteria,pct_viruses,pct_fungi,pct_metazoa,pct_unidentified,top_genus,top_genus_pct" > "$OUT"

for rep in kraken/*.report; do
  srr=$(basename "$rep" .report)

  # reads entering classification: the "R" (root) row counts everything
  # classified, the "U" row everything unclassified.
  classified=$(awk '$4=="R"{print $2+0; exit}' "$rep");  classified=${classified:-0}
  unclass=$(awk '$4=="U"{print $2+0; exit}' "$rep");     unclass=${unclass:-0}
  total=$((classified + unclass))
  [[ "$total" -eq 0 ]] && { echo "[7] $srr has no reads, skipping" >&2; continue; }

  dom () { awk -v n="$1" '$4=="D" && $0 ~ n {print $2+0; exit}' "$rep"; }
  bac=$(dom "Bacteria");  bac=${bac:-0}
  vir=$(dom "Viruses");   vir=${vir:-0}
  euk=$(awk '$4=="D" && /Eukaryota/ {print $2+0; exit}' "$rep"); euk=${euk:-0}
  fun=$(awk '$4=="K" && /Fungi/ {print $2+0; exit}' "$rep"); fun=${fun:-0}
  met=$(awk '$4=="K" && /Metazoa/ {print $2+0; exit}' "$rep"); met=${met:-0}

  # most abundant genus from Bracken
  topline=$(sort -t$'\t' -k6 -gr "kraken/${srr}.bracken" 2>/dev/null | head -1)
  topg=$(echo "$topline" | cut -f1)
  topn=$(echo "$topline" | cut -f6)
  topn=${topn:-0}

  awk -v r="$srr" -v t="$total" -v b="$bac" -v v="$vir" -v f="$fun" \
      -v m="$met" -v u="$unclass" -v g="${topg:-NA}" -v gn="$topn" \
      'BEGIN{printf "%s,%d,%.5f,%.5f,%.5f,%.5f,%.3f,%s,%.4f\n",
             r,t,100*b/t,100*v/t,100*f/t,100*m/t,100*u/t,g,100*gn/t}' >> "$OUT"
done

echo "[7] wrote $OUT"
echo "[7] join it to the run metadata (male, treatment, tissue) and save as"
echo "    data/domain_summary.csv and data/sperm_runs_taxonomy.csv, then run"
echo "    bash bash/02_analyse.sh && bash bash/03_report.sh"
