import sys
import re

lengths = []

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    m = re.match(r'^(\d+)\s+(\d+)$', line)  # "index length"
    if m:
        lengths.append(int(m.group(2)))
        continue
    if re.match(r'^\d+$', line):            # bare length
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
