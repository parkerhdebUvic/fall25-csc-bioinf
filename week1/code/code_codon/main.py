# week1/code/code_codon/main.py
from utils import read_data
from dbg import DBG
import sys


def pjoin(a: str, b: str) -> str:
    return (a.rstrip("/") + "/" + b) if a else b


# setrecursionlimit may not exist in Codon; guard it
if hasattr(sys, "setrecursionlimit"):
    try:
        sys.setrecursionlimit(1_000_000)
    except Exception:
        pass


def main():
    if len(sys.argv) < 2:
        print("usage: main.py <dataset_dir>")
        return

    dataset_dir = sys.argv[1].rstrip("/")
    short1, short2, long1 = read_data(dataset_dir)

    k = 25
    dbg = DBG(k=k, data_list=[short1, short2, long1])

    out_fp = pjoin(dataset_dir, "contig.fasta")
    with open(out_fp, "w") as f:
        for i in range(20):
            c = dbg.get_longest_contig()
            if c is None:
                break
            print(i, len(c))
            # old: f.write('>contig_%d\n' % i)
            # or: f.write(f">contig_{i}\n")
            f.write(">contig_" + str(i) + "\n")
            f.write(c + "\n")


if __name__ == "__main__":
    main()
