#!/usr/bin/env bash
# NOTE: Run locally only (requires BLAST+ and network). Not used in CI.
# brew install ncbi-blast-plus  OR  conda install -c bioconda blast
set -euo pipefail
for d in data1 data2 data3; do
  f="week1/data/${d}/contig.fasta"
  [[ -f "$f" ]] || { echo "Skip ${d}: no contigs"; continue; }
  echo "== ${d} =="
  blastn -task megablast -remote -db nt -query "$f" \
    -outfmt '6 qseqid sacc ssciname staxids pident length evalue bitscore qlen slen' \
    -max_target_seqs 5 -max_hsps 1 | head -5
done
