#!/usr/bin/env python3
"""Select two apparently idle GPUs using two samples; this is not a reservation."""
import csv
import subprocess
import sys
import time

def sample():
    rows = csv.reader(subprocess.check_output(['nvidia-smi', '--query-gpu=index,uuid,memory.used,utilization.gpu', '--format=csv,noheader,nounits'], text=True).splitlines())
    active = set(subprocess.check_output(['nvidia-smi', '--query-compute-apps=gpu_uuid', '--format=csv,noheader'], text=True).splitlines())
    result = {}
    for row in rows:
        index, uuid, memory, util = (v.strip() for v in row)
        if memory.isdigit() and util.isdigit() and int(memory) <= 256 and int(util) == 0 and uuid not in active:
            result[uuid] = (int(memory), index)
    return result

first = sample()
time.sleep(2)
second = sample()
candidates = sorted((max(first[u][0], second[u][0]), second[u][1], u) for u in first.keys() & second.keys())
if len(candidates) < 2:
    sys.exit('STOP: fewer than two GPUs idle in both samples (0% utilization, <=256 MiB, no visible compute process)')
chosen = candidates[:2]
print('Selected GPUs: ' + ', '.join(f'physical {i}, {u}, {m} MiB' for m, i, u in chosen), file=sys.stderr)
print(','.join(u for _, _, u in chosen))
