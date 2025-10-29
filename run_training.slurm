#!/bin/bash
#SBATCH --job-name=lyra_train
#SBATCH --partition=gpupreempt
#SBATCH --time=2:00:00
#SBATCH --nodes=1
#SBATCH --gres=gpu:nvidia_h100_80gb_hbm3_1g.10gb:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --output=logs/train_%j.out
#SBATCH --error=logs/train_%j.err

mkdir -p logs

module load apptainer/1.3.5

cd /home/mva69/NVProject/lyra

# Unset problematic environment variables before running container
unset LD_PRELOAD

apptainer exec --nv \
    --bind $(pwd):/workspace \
    container/lyra.sif \
    bash -c "export LD_LIBRARY_PATH=/opt/conda/envs/lyra/lib:/usr/local/cuda/lib64:\$LD_LIBRARY_PATH && cd /workspace && bash train.sh"
