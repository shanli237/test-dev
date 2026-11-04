#!/usr/bin/env bash
set -euo pipefail
cd /workspace/FuseLink/FuseLink
source scripts/env_multinode.sh
CUDA_VISIBLE_DEVICES="$(python3 scripts/select_idle_gpus.py)"
export CUDA_VISIBLE_DEVICES
# Obtain NIC order from libibverbs, matching FuseLink enumeration.
nic_config="$(python3 - <<'PY'
import os, subprocess, re, ctypes
rows=subprocess.check_output(['nvidia-smi','--query-gpu=index,uuid','--format=csv,noheader'],text=True).splitlines()
indices={r.split(',')[1].strip():r.split(',')[0].strip() for r in rows}
topo=subprocess.check_output(['nvidia-smi','topo','-m'],text=True)
lines=topo.splitlines(); header=lines[0].split(); legend=dict(re.findall(r'(NIC\d+):\s+(\S+)',topo))
selected={}
for logical,uuid in enumerate(os.environ['CUDA_VISIBLE_DEVICES'].split(',')):
 row=next(l.split()[1:] for l in lines if l.startswith('GPU'+indices[uuid]+'\t'))
 near=[legend[h] for h,v in zip(header,row) if h.startswith('NIC') and v=='PXB']
 if len(near)!=1: raise SystemExit('No unique nearest NIC')
 selected[near[0]]=logical
if len(selected)!=2: raise SystemExit('Need two distinct NICs')
lib=ctypes.CDLL('libibverbs.so.1');lib.ibv_get_device_list.restype=ctypes.POINTER(ctypes.c_void_p)
lib.ibv_get_device_name.argtypes=[ctypes.c_void_p];lib.ibv_get_device_name.restype=ctypes.c_char_p
n=ctypes.c_int();devs=lib.ibv_get_device_list(ctypes.byref(n))
ordered=[lib.ibv_get_device_name(devs[i]).decode() for i in range(n.value)]
ordered=[d for d in ordered if d in selected]
if len(ordered)!=2: raise SystemExit('Selected NICs unavailable')
for d in ordered:
 if 'ACTIVE' not in open('/sys/class/infiniband/'+d+'/ports/1/state').read(): raise SystemExit('Inactive NIC')
print('export NCCL_IB_HCA="='+','.join(ordered)+'"')
print('export FUSELINK_NIC2GPU='+','.join(str(selected[d]) for d in ordered))
PY
)"
eval "$nic_config"
export FUSELINK_CHANNEL2NIC=0,1,0,1 NCCL_FUSELINK_NCHANNELS=4 NCCL_MIN_NCHANNELS=4 NCCL_MAX_NCHANNELS=4 NCCL_IB_GID_INDEX=3
if [[ ${1:-mixed} == netonly ]]; then export NCCL_P2P_DISABLE=1 NCCL_SHM_DISABLE=1; fi
if [[ ${4:-FuseLink} == IB ]]; then export NCCL_NET=IB NCCL_NET_PLUGIN=none; fi
printf 'Node %s GPUs=%s NICs=%s NIC2GPU=%s\n' "$(hostname)" "$CUDA_VISIBLE_DEVICES" "$NCCL_IB_HCA" "$FUSELINK_NIC2GPU"
exec /workspace/FuseLink/nccl-tests/build-cuda122-mpi/all_reduce_perf -b "${2:-8}" -e "${3:-64K}" -f 2 -g 2 -w 3 -n 10
