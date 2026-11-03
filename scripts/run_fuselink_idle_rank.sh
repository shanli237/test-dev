#!/usr/bin/env bash
set -euo pipefail
cd /workspace/FuseLink/FuseLink
source scripts/env_multinode.sh
CUDA_VISIBLE_DEVICES="$(python3 scripts/select_idle_gpus.py)"
export CUDA_VISIBLE_DEVICES
# Choose the PCIe-nearest NIC of the first selected GPU, from the physical topology.
NCCL_IB_HCA="=$(python3 - <<'PY'
import os,subprocess,re
rows=subprocess.check_output(['nvidia-smi','--query-gpu=index,uuid','--format=csv,noheader'],text=True).splitlines()
uuid=os.environ['CUDA_VISIBLE_DEVICES'].split(',')[0]
idx=next(r.split(',')[0].strip() for r in rows if r.split(',')[1].strip()==uuid)
topo=subprocess.check_output(['nvidia-smi','topo','-m'],text=True)
lines=topo.splitlines(); header=lines[0].split()
row=next(l.split()[1:] for l in lines if l.startswith('GPU'+idx+'\t'))
legend=dict(re.findall(r'(NIC\d+):\s+(\S+)',topo))
near=[legend[h] for h,v in zip(header,row) if h.startswith('NIC') and v=='PXB']
if len(near)!=1: raise SystemExit('Cannot identify unique nearest NIC')
print(near[0])
PY
)"
export NCCL_IB_HCA
export FUSELINK_NIC2GPU=0 FUSELINK_CHANNEL2NIC=0
export NCCL_FUSELINK_NCHANNELS=1 NCCL_MIN_NCHANNELS=1 NCCL_MAX_NCHANNELS=1 NCCL_IB_GID_INDEX=3
if [[ ${1:-FuseLink} == IB ]]; then
  export NCCL_NET=IB NCCL_NET_PLUGIN=none
fi
if [[ ${3:-mixed} == netonly ]]; then
  export NCCL_P2P_DISABLE=1 NCCL_SHM_DISABLE=1
fi
printf 'Node %s GPUs=%s NIC=%s\n' "$(hostname)" "$CUDA_VISIBLE_DEVICES" "$NCCL_IB_HCA"
exec /workspace/FuseLink/nccl-tests/build-cuda122-mpi/all_reduce_perf -b 8 -e 64K -f 2 -g "${2:-2}" -w 1 -n 3
