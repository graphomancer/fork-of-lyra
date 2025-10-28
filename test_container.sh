#!/bin/bash

# Quick test script for lyra_correct.sif

# Load Apptainer
module load apptainer/1.3.5

# Test 1: Check Python version
echo "=== Testing Python ==="
apptainer exec lyra_correct.sif python --version

# Test 2: Check CUDA compiler
echo ""
echo "=== Testing CUDA ==="
apptainer exec lyra_correct.sif nvcc --version

# Test 3: Check GCC
echo ""
echo "=== Testing GCC ==="
apptainer exec lyra_correct.sif gcc --version

# Test 4: Verify conda environment and PyTorch
echo ""
echo "=== Testing PyTorch ==="
apptainer exec lyra_correct.sif bash -c "source /opt/conda/etc/profile.d/conda.sh && conda activate lyra && python -c 'import torch; print(torch.__version__)'"

# Test 5: GPU test (if on GPU node)
echo ""
echo "=== Testing GPU access ==="
apptainer exec --nv lyra_correct.sif nvidia-smi

echo ""
echo "=== Testing PyTorch GPU ==="
apptainer exec --nv lyra_correct.sif python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'GPU count: {torch.cuda.device_count()}')"

echo ""
echo "Done!"
