#!/bin/bash
# Download VGG16 weights for LPIPS loss using the container

cd /home/mva69/NVProject/lyra

echo "Creating directory for pretrained models..."
mkdir -p ./pretrained_models/torch_hub

echo "Loading apptainer module..."
module load apptainer/1.3.5

echo "Downloading VGG16 weights using container..."
apptainer exec --nv \
  --bind $(pwd):/workspace \
  container/lyra_ubuntu24.sif \
  python3 -c "import os; os.environ['TORCH_HOME'] = '/workspace/pretrained_models/torch_hub'; import torch; import torchvision; print('Downloading VGG16 weights...'); model = torchvision.models.vgg16(weights=torchvision.models.VGG16_Weights.IMAGENET1K_V1); print('✓ VGG16 weights downloaded successfully!')"

echo ""
echo "Verifying download..."
if [ -d "./pretrained_models/torch_hub/hub/checkpoints" ]; then
    echo "✓ Download successful!"
    echo "Files in cache:"
    ls -lh ./pretrained_models/torch_hub/hub/checkpoints/
else
    echo "✗ Download may have failed - directory not found"
    exit 1
fi
