#!/bin/bash

# Size of swapfile in gigabytes
SWAP_SIZE=2G

# Check if swap is already enabled
if swapon --show | grep -q "/swapfile"; then
    echo "✅ Swapfile already exists and is enabled."
else
    echo "⚠️ Swapfile not found. Creating ${SWAP_SIZE} swapfile..."
    
    # Create swap file
    sudo fallocate -l ${SWAP_SIZE} /swapfile
    
    # Verify file creation
    if [ ! -f /swapfile ]; then
        echo "❌ Failed to create swapfile. Fallback to dd..."
        sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
    fi

    # Set permissions
    sudo chmod 600 /swapfile
    
    # Make it swap
    sudo mkswap /swapfile
    
    # Enable swap
    sudo swapon /swapfile
    
    # Persist in fstab
    if ! grep -q "/swapfile" /etc/fstab; then
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
        echo "✅ Added swapfile to /etc/fstab"
    fi
    
    echo "✅ Swap enabled successfully!"
    free -h
fi
