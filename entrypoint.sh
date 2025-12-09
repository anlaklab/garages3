#!/bin/sh
set -e

# Check required environment variables
if [ -z "$RPC_SECRET" ]; then
    echo "ERROR: RPC_SECRET environment variable is required"
    echo "Generate with: openssl rand -hex 32"
    exit 1
fi

if [ -z "$ADMIN_TOKEN" ]; then
    echo "ERROR: ADMIN_TOKEN environment variable is required"
    echo "Generate with: openssl rand -base64 32"
    exit 1
fi

# Substitute environment variables in config template
sed -e "s|__RPC_SECRET__|$RPC_SECRET|g" \
    -e "s|__ADMIN_TOKEN__|$ADMIN_TOKEN|g" \
    /etc/garage.toml.template > /etc/garage.toml

echo "Configuration generated successfully"
echo "Starting Garage server..."

# Start Garage
exec /garage server
