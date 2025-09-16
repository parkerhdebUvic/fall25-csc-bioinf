#!/usr/bin/env bash
# quiet, print-only evaluator
# (Try to raise stack size; needed for data4 on Linux. macOS may refuse—ignore.)
ulimit -s 8192000 || true
set -euo pipefail

PY="python3"
CODE_PY="week1/code/code_python/main.py"
CODE_CODON="week1/code/code_codon/main.py"

DATA_DIR="week1/data"
N50_HELPER="week1/code/n50_helper.py"

# Allow quick tests: DATASETS="data1" bash week1/evaluate.sh
DATASETS="${DATASETS:-data1 data2 data3 data4}"

CODON_BIN="${CODON_BIN:-codon}"
command -v "$CODON_BIN" >/dev/null 2>&1 || CODON_BIN="$HOME/.codon/bin/codon"

fmt_hms () { local S=$1; printf "%d:%02d:%02d" $((S/3600)) $(((S%3600)/60)) $((S%60)); }

echo -e "Dataset\tLanguage \tRuntime \tN50"
echo "-------------------------------------------------------------------------------------------------------"

for d in $DATASETS; do
  ds="${DATA_DIR}/${d}"
  [[ -d "${ds}" ]] || { echo "⚠️  Skipping ${d}: ${ds} not found" >&2; continue; }

  # require FASTAs
  req=(short_1.fasta short_2.fasta long.fasta)
  have_all=1
  for f in "${req[@]}"; do
    [[ -f "${ds}/${f}" ]] || { have_all=0; break; }
  done
  if [[ $have_all -eq 0 ]]; then
    echo "⚠️  Skipping ${d}: missing FASTA(s) in ${ds}" >&2
    continue
  fi

  # -------- Python (capture stdout inline) --------
  start=$(date +%s)
  py_out="$("${PY}" "${CODE_PY}" "${ds}")"
  py_secs=$(( $(date +%s) - start ))
  py_rt=$(fmt_hms "${py_secs}")

  py_lines="$(printf "%s\n" "$py_out" | grep -E '^[0-9]+\s+[0-9]+$|^[0-9]+$' || true)"
  if [[ -n "$py_lines" ]]; then
    py_n50="$(printf "%s\n" "$py_lines" | ${PY} "${N50_HELPER}")"
  else
    py_n50=0
  fi
  printf "%s\t%s\t\t%s\t\t%s\n" "${d}" "python" "${py_rt}" "${py_n50}"

  # -------- Codon (cd into code_codon; capture inline) --------
  start=$(date +%s)
  if ! co_out="$(cd week1/code/code_codon && "$CODON_BIN" run -release -plugin seq "main.py" "../../data/${d}")"; then
    printf "%s\t%s\t\t%s\t\t%s\n" "${d}" "codon" "ERROR" "NA"
    continue
  fi
  co_secs=$(( $(date +%s) - start ))
  co_rt=$(fmt_hms "${co_secs}")

  co_lines="$(printf "%s\n" "$co_out" | grep -E '^[0-9]+\s+[0-9]+$|^[0-9]+$' || true)"
  if [[ -n "$co_lines" ]]; then
    co_n50="$(printf "%s\n" "$co_lines" | ${PY} "${N50_HELPER}")"
  else
    co_n50=0
  fi
  printf "%s\t%s\t\t%s\t\t%s\n" "${d}" "codon" "${co_rt}" "${co_n50}"

  # Optional: warn if outputs differ (but N50 matches)
  # if [[ "$py_out" != "$co_out" ]]; then
  #   if [[ "$py_n50" != "$co_n50" ]]; then
  #     echo "⚠️  ${d}: Python vs Codon outputs differ AND N50 differ (${py_n50} vs ${co_n50})." >&2
  #   else
  #     echo "ℹ️  ${d}: Outputs differ but N50 matches (${py_n50})." >&2
  #   fi
  # fi
done
