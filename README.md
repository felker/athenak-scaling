# athenak-scaling
Testing AthenaK scaling on ALCF Polaris

Run `ln -s -f ../../.githooks/pre-commit .git/hooks/pre-commit` (yes, `../../` is the correct relative path even when `ln` is run from top-level repository directory, since it is relative to `.git/hooks/`) in the main directory of the repository to install a hook that clears Jupyter notebook outputs before committing changes.

See [`results/polaris_scaling.ipynb`](results/polaris_scaling.ipynb) for notes on programming environment, compilation, and execution. 

## Changes from results (AT, May-June 2022) to post-AT machine behavior
- Environment Modules and Tcl-based Cray modulefiles ----> Lmod and Lua-based Cray modulefiles
- During AT, the default modules were fine. All I had to do was run `module load craype-accel-nvidia80` during compile-time and export the CUDA-aware MPI environment variable during runtime.
- Default PE was `PrgEnv-nvidia`. Now, that is deprecated and `PrgEnv-nvhpc` is the default
- Default modules included `cudatoolkit/11.6` (written by Ti Leggett), or it was loaded by `craype-accel-nvidia80`? See `module list` output saved for posterity in notebok. New Cray `cudatoolkit-standalone/11.4.4` modulefile is Lua. The old `cudatoolkit` would set `PKG_CONFIG_PATH` that would make sure that `#include <cuda_runtime.h>` would be found by the compiler. New one does not use pkg-config and does not set `CPATH`. Need to manually pass `-I  $NVIDIA_PATH/cuda/include/` to compiler and `-L${NVIDIA_PATH}/cuda/lib64 -lcudart` to linker if you need it. 

## Reminder: GPUDirect RDMA and CUDA-aware MPI configuration
See example https://github.com/felker/cuda-aware-mpi-example

**Compile time requirement:**
```
> module show craype-accel-nvidia80
...
setenv("CRAY_ACCEL_TARGET","nvidia80")
setenv("CRAY_TCMALLOC_MEMFS_FORCE","1")
setenv("CRAYPE_LINK_TYPE","dynamic")
```
A warning is emitted during compilation of a CUDA-aware MPI program if `-target-accel=nvidia80` or `CRAY_ACCEL_TARGET` isn't used (and `CRAYPE_LINK_TYPE` is not set to dynamic?).

https://docs.nersc.gov/development/programming-models/mpi/cray-mpich/
> The GTL (GPU Transport Layer) library needs to be linked for MPI communication involving GPUs. To make the library detectable and linked, you need to set the accelerator target environment variable CRAY_ACCEL_TARGET to nvidia80 or use the compile flag -target-accel=nvidia80. Otherwise, you may get the following runtime error:

```
MPIDI_CRAY_init: GPU_SUPPORT_ENABLED is requested, but GTL library is not linked
```

Ye:
> `craype-accel-nvidia80` adds `--gpu=cc80` but doesn't control using GPU or not. It still require user controlling `-acc` or `-cuda` to enable GPU.
> `craype-accel-nvidia80` also links GTL library for GPU-aware MPI. You may still link it manually when not using `craype-accel-nvidia80 ` module.


**Cray Runtime requirement:**
```
export MPICH_GPU_SUPPORT_ENABLED=1
```
> Enables a parallel application to perform MPI operations with communication buffers that are on GPU-attached memory regions.

https://www.olcf.ornl.gov/wp-content/uploads/2021/04/HPE-Cray-MPI-Update-nfr-presented.pdf



## Post-AT `PrgEnv-nvidia` vs `PrgEnv-nvhpc`

Only meaningful Lua source difference is:
```
> diff /opt/cray/pe/lmod/modulefiles/core/PrgEnv-nvidia/8.3.3.lua /opt/cray/pe/lmod/modulefiles/core/PrgEnv-nvhpc/8.3.3.lua
...

< if (not isloaded("nvidia")) then
<     load("nvidia")
---
> if (not isloaded("nvhpc")) then
>     load("nvhpc")
```
