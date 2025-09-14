import sys, re

lengths = []

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    # Strict: only lines "index length"
    m = re.match(r'^(\d+)\s+(\d+)$', line)
    if m:
        lengths.append(int(m.group(2)))
        continue
    # Or accept a bare integer line (one number only)
    if re.match(r'^\d+$', line):
        lengths.append(int(line))

if not lengths:
    print(0)
    sys.exit(0)

lengths.sort(reverse=True)
total = sum(lengths)
target = total / 2.0

cum = 0
for L in lengths:
    cum += L
    if cum >= target:
        print(L)
        break
