#!/bin/bash
# Download VGG16 weights directly using wget (avoids SSL issues in container)

cd /home/mva69/NVProject/lyra

echo "Creating directory for VGG16 weights..."
mkdir -p ./pretrained_models/torch_hub/hub/checkpoints

echo "Downloading VGG16 weights from PyTorch..."
wget https://download.pytorch.org/models/vgg16-397923af.pth \
  -O ./pretrained_models/torch_hub/hub/checkpoints/vgg16-397923af.pth

echo ""
echo "Verifying download..."
if [ -f "./pretrained_models/torch_hub/hub/checkpoints/vgg16-397923af.pth" ]; then
    echo "✓ Download successful!"
    echo "File details:"
    ls -lh ./pretrained_models/torch_hub/hub/checkpoints/vgg16-397923af.pth
else
    echo "✗ Download failed - file not found"
    exit 1
fi

echo ""
echo "VGG16 weights are ready for training!"
