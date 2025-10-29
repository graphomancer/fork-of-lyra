#!/bin/bash
# Script to install Hugging Face CLI following the cluster wiki instructions

set -e  # Exit on error

echo "=========================================="
echo "Installing Hugging Face CLI"
echo "=========================================="

# Step 1: Load Python module
echo "Step 1: Loading Python module..."
module load python

# Step 2: Create virtual environment
echo "Step 2: Creating virtual environment..."
VENV_DIR="${1:-./hf_venv}"
if [ -d "$VENV_DIR" ]; then
    echo "Virtual environment already exists at $VENV_DIR"
    read -p "Do you want to overwrite it? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$VENV_DIR"
    else
        echo "Aborting installation."
        exit 1
    fi
fi

virtualenv --no-download "$VENV_DIR"

# Step 3: Activate virtual environment
echo "Step 3: Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Step 4: Upgrade pip
echo "Step 4: Upgrading pip..."
pip install --upgrade pip --no-index

# Step 5: Install huggingface_hub
echo "Step 5: Installing huggingface_hub..."
pip install --no-index huggingface_hub

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "To use the Hugging Face CLI:"
echo "  1. Activate the virtual environment:"
echo "     source $VENV_DIR/bin/activate"
echo ""
echo "  2. Download models using:"
echo "     HF_HUB_DISABLE_XET=1 hf download --max-workers=1 <model-name>"
echo ""
echo "Example:"
echo "  HF_HUB_DISABLE_XET=1 hf download --max-workers=1 HuggingFaceH4/zephyr-7b-beta"
echo ""
echo "Note: Model downloads must be performed on a login node!"
echo "=========================================="
