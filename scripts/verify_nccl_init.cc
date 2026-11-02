#include <nccl.h>
#include <cuda_runtime.h>
#include <cstdio>
#include <chrono>
int main() {
  setbuf(stdout, nullptr);
  int version=0; ncclGetVersion(&version);
  printf("NCCL %d: starting ncclCommInitAll on GPUs 0,1\n", version);
  auto start=std::chrono::steady_clock::now();
  ncclComm_t comms[2]; int devices[2]={0,1};
  ncclResult_t result=ncclCommInitAll(comms,2,devices);
  double seconds=std::chrono::duration<double>(std::chrono::steady_clock::now()-start).count();
  printf("ncclCommInitAll: %s (%.2f seconds)\n",ncclGetErrorString(result),seconds);
  if(result!=ncclSuccess) return 1;
  for(int i=0;i<2;i++) {
    int count=0,rank=-1,device=-1;
    if(ncclCommCount(comms[i],&count)!=ncclSuccess || ncclCommUserRank(comms[i],&rank)!=ncclSuccess || ncclCommCuDevice(comms[i],&device)!=ncclSuccess) return 2;
    printf("rank=%d device=%d count=%d\n",rank,device,count);
    if(count!=2 || rank!=i || device!=i) return 3;
    if(ncclCommDestroy(comms[i])!=ncclSuccess) return 4;
  }
  puts("PASS: both NCCL communicators initialized and destroyed");
}
