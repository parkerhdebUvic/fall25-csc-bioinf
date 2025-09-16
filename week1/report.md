# Week 1 Report — De Bruijn Assembler (Python → Codon)

## 1. Setup
- Repo structure matches assignment (code/, data/, test/).
- CI: `.github/workflows/actions.yml` installs Codon + seq plugin, runs `bash week1/evaluate.sh`.
- Python: `week1/code/code_python/*`
- Codon: `week1/code/code_codon/*` (no matplotlib; no pathlib/os.path; no sys.path hacks)

## 2. How to run (local)
```bash
python3 week1/code/code_python/main.py week1/data/data1 > week1/test/data1.python.out
codon run -plugin seq week1/code/code_codon/main.py week1/data/data1 > week1/test/data1.codon.out
bash week1/evaluate.sh
