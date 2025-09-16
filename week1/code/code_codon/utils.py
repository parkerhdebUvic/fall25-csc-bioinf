# week1/code/code_codon/utils.py
def pjoin(a: str, b: str) -> str:
    return (a.rstrip("/") + "/" + b) if a else b


def read_fasta(path: str, name: str):
    seqs, s = [], []
    with open(pjoin(path, name), "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.startswith(">"):
                if s:
                    seqs.append("".join(s))
                    s = []
            else:
                s.append(line)
    if s:
        seqs.append("".join(s))
    return seqs


def read_data(path: str):
    short1 = read_fasta(path, "short_1.fasta")
    short2 = read_fasta(path, "short_2.fasta")
    long1 = read_fasta(path, "long.fasta")
    return short1, short2, long1
