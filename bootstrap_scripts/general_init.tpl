#!/bin/bash
set -eux

MOUNT_POINT="${mount_point}"

# Identify the secondary disks by matching size
SECONDARY_DISK=$(lsblk -nd -o NAME,TYPE,SIZE | grep -E 'nvme|sd' | awk '$2=="disk" && $3=="${ec2_secondary_volume_size}G" {print "/dev/"$1}' | tail -n 1)

if [ -z "$${SECONDARY_DISK}" ]; then
    echo "Error: secondary disk with capacity ${ec2_secondary_volume_size}G not found."
    exit 1
fi

# Format if necessary
if ! blkid $${SECONDARY_DISK}; then
    mkfs.ext4 $${SECONDARY_DISK}
fi

mkdir -p $${MOUNT_POINT}

# Add to fstab if not already there
if ! grep -qs $${SECONDARY_DISK} /etc/fstab; then
    echo "$${SECONDARY_DISK} $${MOUNT_POINT} ext4 defaults,nofail 0 2" >> /etc/fstab
fi

mount -a

# Change ownership so the default user ubuntu user can write to it
chown -R ubuntu:ubuntu $${MOUNT_POINT}