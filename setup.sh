#!/bin/bash
# Garage S3 Setup Script
# Run this after the container is running to initialize the cluster

set -e

echo "=== Garage S3 Initial Setup ==="
echo ""

# Wait for garage to be ready
echo "Waiting for Garage to start..."
sleep 5

# Get node ID
echo "Getting node information..."
docker exec garage garage status

# Get the node ID (first node)
NODE_ID=$(docker exec garage garage status 2>/dev/null | grep -E "^[a-f0-9]+" | head -1 | awk '{print $1}')

if [ -z "$NODE_ID" ]; then
    echo "Error: Could not get node ID. Is Garage running?"
    exit 1
fi

echo ""
echo "Node ID: $NODE_ID"
echo ""

# Configure the layout (assign capacity to this node)
echo "Configuring cluster layout..."
docker exec garage garage layout assign -z dc1 -c 1G "$NODE_ID"

# Apply the layout
echo "Applying layout..."
docker exec garage garage layout apply --version 1

echo ""
echo "=== Layout configured ==="
docker exec garage garage layout show

echo ""
echo "=== Creating default bucket and access key ==="

# Create a bucket
docker exec garage garage bucket create default

# Create an access key
echo ""
echo "Creating access key..."
docker exec garage garage key create default-key

# Grant permissions
echo ""
echo "Granting permissions to bucket..."
docker exec garage garage bucket allow --read --write --owner default --key default-key

# Enable website hosting for the bucket
echo ""
echo "Enabling website hosting on default bucket..."
docker exec garage garage bucket website --allow default

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Your S3 credentials:"
docker exec garage garage key info default-key

echo ""
echo "=== Quick Test ==="
echo "You can test with aws-cli:"
echo ""
echo "aws --endpoint-url http://localhost:3900 s3 ls"
echo ""
