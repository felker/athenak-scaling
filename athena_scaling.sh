#!/bin/bash -l
#PBS -q run_next
#PBS -l select=16:ncpus=64:ngpus=4,walltime=00:30:00
#PBS -j n
#PBS -k doe
#PBS -S /bin/bash
#PBS -j oe

#!/usr/bin/env bash

# By default, PBS spools your output on the compute node and then uses scp to move it the # destination directory after the job finishes. Since we have globally mounted file systems # it is highly recommended that you use the -k option to write directly to the destination # the doe stands for direct, output, error #PBS -k doe #PBS -o <path for stdout> #PBS -e <path for stderr>

# If you want to merge stdout and stderr, use the -j option
# oe=merge stdout/stderr to stdout, eo=merge stderr/stdout to stderr, n=don't merge
##PBS -j oe

# qsub -q run_next -I -l select=16:ncpus=64:ngpus=4,walltime=03:00:00 -j oe -S /bin/bash

# ALCF Polaris
# 560 nodes
# 4x A100 GPUs per node
# = 2240 A100s

export MPICH_GPU_SUPPORT_ENABLED=1
module load craype-accel-nvidia80

pwd
cd $PBS_O_WORKDIR
# cd /home/felker/athenak/build/src
pwd

echo
module list
echo $PATH
echo
echo $LD_LIBRARY_PATH

node_count=(1 2 4 8 16)  # 32 64 128 256)
num_ranks_per_node=4
block_nx=32
#multinode_summary_filename="athena_weak_multinode_mpi.txt"
csv_result_file="athena_weak_multinode_mpi.csv"

# Define mesh for single MPI rank solver:
# Option #1: In terms of num MeshBlocks in each dim
# (problem size and runtime will change for block_nx loop)
n1_mb=8
n2_mb=8
n3_mb=8
# 256^3 base resolution for 32^3 MeshBlocks
num_blocks_per_rank=$((${n1_mb}*${n2_mb}*${n3_mb}))

for num_nodes in ${node_count[*]}
do
    num_ranks=$((${num_nodes} * ${num_ranks_per_node}))
    mesh_nx1=$((${n1_mb} * ${block_nx}))
    mesh_nx2=$((${n2_mb} * ${block_nx}))
    # Simply stack each additional MPI rank's MeshBlocks in x3
    mesh_nx3=$((${n3_mb} * ${block_nx} * ${num_ranks}))
    runtime_cmd="meshblock/nx1=${block_nx} meshblock/nx2=${block_nx} meshblock/nx3=${block_nx} mesh/nx1=${mesh_nx1} mesh/nx2=${mesh_nx2} mesh/nx3=${mesh_nx3} 2>&1 | tee bare_athena_output.txt" # mesh/x3min=${mesh_x3min} mesh/x3max=${mesh_x3max}"
    echo "mpiexec -np ${num_ranks} -ppn ${num_ranks_per_node} ./gpu_affinity.sh ${runtime_cmd}"
    mpiexec -np ${num_ranks} -ppn ${num_ranks_per_node} ./gpu_affinity.sh ${runtime_cmd}
    echo -n "${num_nodes} " | tee -a ${csv_result_file} # >> ${multinode_summary_filename}

    # Trim the performance metrics from the Athena++ stdout
    tail -n 2 bare_athena_output.txt | sed 's/.* = //' | xargs -n2 | tee -a ${csv_result_file} # >> ${multinode_summary_filename}
done
