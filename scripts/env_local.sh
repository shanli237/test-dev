# Source this file from bash to use the local build.
_fuselink_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export CUDA_HOME="${CUDA_HOME:-/usr/local/cuda-12.2}"
export LD_LIBRARY_PATH="$_fuselink_root/build/lib:$_fuselink_root/nccl/build/lib:$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}"
export NCCL_NET_PLUGIN=fuselink
export NCCL_DEBUG=INFO
unset _fuselink_root
