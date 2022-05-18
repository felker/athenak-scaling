#!/bin/bash
gpu=$((${PMI_RANK} % 4))
export CUDA_VISIBLE_DEVICES=$gpu
echo “RANK= ${PMI_RANK} gpu= ${gpu}”
echo /home/felker/athenak/build/src/athena -i /home/felker/athenak/inputs/grmhd/gr_torus_mhd.athinput $@
exec /home/felker/athenak/build/src/athena -i /home/felker/athenak/inputs/grmhd/gr_torus_mhd.athinput $@
# mpiexec -np 4 ./gpu_affinity.sh
