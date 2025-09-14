#!/usr/bin/env bash
set -euxo pipefail

PY="python3"
CODE_PY="week1/code/code_python/main.py"
CODE_CODON="week1/code/code_codon/main_codon.py"
DATA_DIR="week1/data"
OUT_DIR="week1/test"
N50_HELPER="week1/code/n50_helper.py"

mkdir -p "${OUT_DIR}"

fmt_hms () { local S=$1; printf "%d:%02d:%02d" $((S/3600)) $(((S%3600)/60)) $((S%60)); }

run_and_time () {
  local outfile="$1"; shift
  local start end
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

  # Python
  py_out="${OUT_DIR}/${d}.python.out"
  py_secs=$(run_and_time "${py_out}" "${PY}" "${CODE_PY}" "${ds}")
  py_rt=$(fmt_hms "${py_secs}")
  py_n50=$(grep -E '^[0-9]+\s+[0-9]+$|^[0-9]+$' "${py_out}" | ${PY} "${N50_HELPER}")
  echo -e "${d}\tpython\t${py_rt}\t${py_n50}"

  # Codon
  co_out="${OUT_DIR}/${d}.codon.out"
  set +e
  co_secs=$(run_and_time "${co_out}" codon run -release -plugin seq "${CODE_CODON}" "${ds}")
  codon_rc=$?
  set -e
  if [[ ${codon_rc} -ne 0 ]]; then
    echo -e "${d}\tcodon\tERROR\tNA"
    continue
  fi
  co_rt=$(fmt_hms "${co_secs}")
  co_n50=$(grep -E '^[0-9]+\s+[0-9]+$|^[0-9]+$' "${co_out}" | ${PY} "${N50_HELPER}")
  echo -e "${d}\tcodon\t${co_rt}\t${co_n50}"

  # Compare outputs (exact or N50)
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
