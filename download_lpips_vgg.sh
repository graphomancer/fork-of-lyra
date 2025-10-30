#!/bin/bash
# Download LPIPS VGG weights for kiui.lpips library

cd /home/mva69/NVProject/lyra

echo "Creating directory for LPIPS VGG weights..."
mkdir -p ./pretrained_models/torch_hub/hub/checkpoints

echo ""
echo "Downloading LPIPS VGG weights from PerceptualSimilarity..."
wget -q --show-progress https://github.com/richzhang/PerceptualSimilarity/raw/master/lpips/weights/v0.1/vgg.pth \
  -O ./pretrained_models/torch_hub/hub/checkpoints/vgg.pth

if [ $? -eq 0 ]; then
    echo "✓ LPIPS VGG weights downloaded successfully!"
    echo ""
    echo "File details:"
    ls -lh ./pretrained_models/torch_hub/hub/checkpoints/vgg.pth
else
    echo "✗ Failed to download LPIPS VGG weights"
    exit 1
fi

echo ""
echo "LPIPS VGG weights are ready for training!"
