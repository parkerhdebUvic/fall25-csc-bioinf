#!/usr/bin/env bash
set -euxo pipefail

PY="python3"
CODE_PY="week1/code/main.py"
CODE_CODON="week1/code/main.codon.py"   # create this (start as a copy of main.py)
DATA_DIR="week1/data"
OUT_DIR="week1/test"
N50_HELPER="week1/code/n50_helper.py"

mkdir -p "${OUT_DIR}"

fmt_hms () { local S=$1; printf "%d:%02d:%02d" $((S/3600)) $(((S%3600)/60)) $((S%60)); }

run_and_time () {
  # $1 outfile, $2.. cmd
  local outfile="$1"; shift
  local start end dur
  start=$(date +%s)
  "$@" > "${outfile}"
  end=$(date +%s)
  echo $((end - start))
}

echo -e "Dataset\tLanguage\tRuntime\tN50"
echo "----------------------------------------------"

for d in data1 data2 data3 data4; do
  ds="${DATA_DIR}/${d}"
  [[ -d "${ds}" ]] || { echo "⚠️  Skipping ${d}: ${ds} not found" >&2; continue; }

  # --- Python run ---
  py_out="${OUT_DIR}/${d}.python.out"
  py_secs=$(run_and_time "${py_out}" "${PY}" "${CODE_PY}" "${ds}")
  py_rt=$(fmt_hms "${py_secs}")
  py_n50=$(${PY} "${N50_HELPER}" < "${py_out}")
  echo -e "${d}\tpython\t${py_rt}\t${py_n50}"

  # --- Codon run ---
  co_out="${OUT_DIR}/${d}.codon.out"
  # If you don't have a Codonized file yet, try running the Python file; if it fails, continue to next dataset.
  codon_target="${CODE_CODON}"
  [[ -f "${codon_target}" ]] || codon_target="${CODE_PY}"

  # We don't want a Codon failure to kill the Python rows; catch and continue.
  set +e
  co_secs=$(run_and_time "${co_out}" codon run -release -plugin seq "${codon_target}" "${ds}")
  codon_rc=$?
  set -e

  if [[ ${codon_rc} -ne 0 ]]; then
    echo -e "${d}\tcodon\tERROR\tNA"
    continue
  fi

  co_rt=$(fmt_hms "${co_secs}")
  co_n50=$(${PY} "${N50_HELPER}" < "${co_out}")
  echo -e "${d}\tcodon\t${co_rt}\t${co_n50}"

  # --- Compare outputs (best-effort) ---
  set +e
  diff -q "${py_out}" "${co_out}" >/dev/null
  same_out=$?
  set -e

  if [[ ${same_out} -ne 0 ]]; then
    if [[ "${py_n50}" != "${co_n50}" ]]; then
      echo "⚠️  ${d}: Python vs Codon outputs differ AND N50 differ (${py_n50} vs ${co_n50})." >&2
    else
      echo "ℹ️  ${d}: Outputs differ but N50 matches (${py_n50})." >&2
    fi
  fi
done
