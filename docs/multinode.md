# 双机 FuseLink 验证

节点：11.163.39.111（启动节点）、11.163.39.110。每台一个 MPI 进程，
每进程使用两张 GPU，共四个 rank。脚本当前要求两边项目路径均为
`/workspace/FuseLink/FuseLink`，nccl-tests 位于 `/workspace/FuseLink/nccl-tests`。

本机双 GPU RDMA 小规模正确性测试已通过；跨机测试尚未验证。
硬件相同仍需确认 RoCE 网络互通、两张 GPU 空闲、网卡枚举顺序相同。

## 两台机器都执行

拉取主仓库代码，然后初始化 NCCL 子模块：

```bash
cd /workspace/FuseLink/FuseLink
git pull --ff-only
git submodule update --init nccl
```

NCCL 子模块的本地源码修改不会随主仓库自动传播，需应用补丁：

```bash
# 若 reverse 检查成功，说明补丁已应用，不要重复应用。
if git -C nccl apply --reverse --check ../patches/nccl-local-compat.patch; then
  echo 'NCCL patch already applied'
else
  git -C nccl apply --check ../patches/nccl-local-compat.patch &&
  git -C nccl apply ../patches/nccl-local-compat.patch
fi
```

补丁包含设备运行库链接和 CUDA 13 stream capture 接口兼容处理。
其他子模块修改（例如 pkg/debian/copyright）未包含在补丁里。

要求已安装 CUDA Toolkit 12.2（`/usr/local/cuda-12.2`）。安装构建依赖：

```bash
apt-get update
apt-get install -y g++-12 make libibverbs-dev openmpi-bin libopenmpi-dev
source scripts/env_cuda122.sh
bash scripts/build_local.sh
```

如果原目录有其他 CUDA 版本的编译产物，先备份原构建目录并重新编译，
不要仅依赖 make 的时间戳判断。仓库历史已跟踪部分二进制和日志，拉取到的
二进制不等于本机已验证的构建产物。

nccl-tests 是主仓库外的独立项目，需要在两边单独准备相同版本：

```bash
# 仅在目录不存在时克隆；已有目录则保留并核对两端 commit。
git clone https://github.com/NVIDIA/nccl-tests.git /workspace/FuseLink/nccl-tests
```

本次本机测试使用 nccl-tests commit 前缀 `afd59ab`；两端应固定同一版本。
编译 MPI 版本：

```bash
source scripts/env_cuda122.sh
make -C /workspace/FuseLink/nccl-tests -j4 \
  BUILDDIR=build-cuda122-mpi MPI=1 MPI_HOME=/usr \
  MPI_INCLUDE=/usr/lib/x86_64-linux-gnu/openmpi/include \
  CUDA_HOME="$CUDA_HOME" NCCL_HOME="$PWD/nccl/build" CXX="$CXX" \
<<<<<<< HEAD
  NVCC_GENCODE='-gencode=arch=compute_89,code=compute_89'
=======
  NVCC_GENCODE='-gencode=arch=compute_89,code=[sm_89,compute_89]'
>>>>>>> origin/main
```

## 在 11.163.39.111 启动

配置 root 到第二台的免密 SSH，确认远程运行环境可访问 GPU 和 RDMA 设备：

```bash
ssh root@11.163.39.110 'hostname; test -x /workspace/FuseLink/nccl-tests/build-cuda122-mpi/all_reduce_perf; command -v orted'
mpirun --allow-run-as-root --hostfile config/hosts.two_nodes \
  -np 2 --map-by ppr:1:node hostname
bash scripts/test_multinode.sh
```

两台机器均从 scripts/env_multinode.sh 加载各自环境。配置为：
eth0 用于 bootstrap，mlx5_bond_5/6 用于 RDMA，NIC 对应可见 GPU 0/1，
四个通道映射到 NIC 0/1/0/1。必须保留两张 GPU 对进程可见。
`NCCL_DMABUF_ENABLE=0` 避开本机验证发现的 DMA-BUF EINVAL 错误，使用传统 GDR。

通过条件：四个 rank 完成初始化，跨节点日志出现 NET/FuseLink/.../GDRDMA，
测试正常退出且 Out of bounds values 为 0 OK。
日志保存在启动节点 build/logs/multinode.log。

系统安装、SSH 配置、驱动、CUDA Toolkit 不会被 Git 同步。

<<<<<<< HEAD
## .110 Docker SSH（22222 端口）

.110 当前容器的独立 SSH 服务监听 `11.163.39.110:22222`，仅接受 root 公钥登录。
22 端口属于宿主环境，不用于启动本容器中的 MPI。
将 .111 启动用户的公钥加入本容器 `/root/.ssh/authorized_keys`（权限 600）。
在 .111 将 `config/ssh.node110.example` 中的配置合并到 `~/.ssh/config`，
按实际密钥路径调整 IdentityFile。不要给所有 MPI 节点统一设置 22222 端口。

```bash
# 在 .111 执行，首次确认主机公钥指纹后写入 known_hosts
ssh -o BatchMode=no root@11.163.39.110 \
  'test -f /.dockerenv && echo DOCKER_SSH_OK; command -v orted'
# 随后验证 MPI 的远程启动环境
mpirun --allow-run-as-root --hostfile config/hosts.two_nodes -np 2 \
  --map-by ppr:1:node --bind-to none \
  bash -c 'hostname; test -f /.dockerenv && echo DOCKER; command -v orted'
```

.110 容器 ED25519 指纹：
`SHA256:qKnd4SGvCgWSH4UA5QGxpI9tUsjVhQze8GA/UDW+ZIo`。
当前服务已启动；容器重启后运行 `bash scripts/start_container_sshd.sh`。
此服务没有自动接入容器 entrypoint；重建容器时需持久化或重新部署
`/etc/ssh/sshd_config_fuselink`、host keys 和 `/root/.ssh/authorized_keys`。
=======
也可使用 `bash scripts/build_mpi_tests.sh` 构建 MPI 测试程序。
本机测试要求 nccl-tests 包含 PTX；仅 sm_89 二进制曾报 no kernel image。
>>>>>>> origin/main
