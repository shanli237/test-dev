# Source on each node; GPU and NIC numbering must match the local topology.
_fuselink_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$_fuselink_dir/scripts/env_cuda122.sh"
source "$_fuselink_dir/scripts/env_local.sh"
unset _fuselink_dir
export NCCL_NET=FuseLink
export NCCL_SOCKET_IFNAME='=eth0'
export NCCL_IB_HCA='=mlx5_bond_5,mlx5_bond_6'
export FUSELINK_NIC2GPU=0,1
export FUSELINK_CHANNEL2NIC=0,1,0,1
export NCCL_FUSELINK_NCHANNELS=4 NCCL_MIN_NCHANNELS=4 NCCL_MAX_NCHANNELS=4
export NCCL_DMABUF_ENABLE=0 NCCL_NET_GDR_LEVEL=SYS
export NCCL_CUMEM_ENABLE=1 NCCL_NET_SHARED_BUFFERS=0
export NCCL_PROTO=Simple NCCL_ALGO=Ring
# Permit normal intra-node transports while cross-node traffic uses FuseLink.
unset NCCL_P2P_DISABLE NCCL_SHM_DISABLE
