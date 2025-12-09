# Garage S3 Deployment Guide for Dokploy

## Overview

This setup deploys Garage S3-compatible storage with:
- **s3.anlak.es** - S3 API endpoint (port 3900)

## Files Structure

```
├── Dockerfile            # Docker build configuration
├── entrypoint.sh         # Startup script with env var substitution
├── garage.toml           # Garage configuration template
├── .env.example          # Environment variables reference
└── setup.sh              # Initial cluster setup script
```

## Dokploy Deployment Steps

### 1. Create a New Application in Dokploy

1. Go to Dokploy dashboard
2. Create a new project (e.g., "garage-s3")
3. Add Application → Select "GitHub" or "Git"
4. Connect to repository: `anlaklab/garages3`

### 2. Configure Environment Variables

In Dokploy, go to **Environment** and add:

```
RPC_SECRET=<generate-with-openssl-rand-hex-32>
ADMIN_TOKEN=<generate-with-openssl-rand-base64-32>
```

Generate secrets:
```bash
openssl rand -hex 32      # for RPC_SECRET
openssl rand -base64 32   # for ADMIN_TOKEN
```

### 3. Configure Volumes (Persistent Storage)

In Dokploy, add these volume mounts:

| Container Path | Description |
|----------------|-------------|
| `/var/lib/garage/meta` | Metadata storage |
| `/var/lib/garage/data` | Object data storage |

### 4. Configure Domain in Dokploy

#### S3 API
- **Domain**: `s3.anlak.es`
- **Port**: `3900`
- **SSL**: Enable (Let's Encrypt)

### 5. Deploy and Initialize

1. Deploy the application in Dokploy
2. Open the terminal in Dokploy (or SSH into your server)
3. Initialize the cluster:

```bash
# Find your container name (usually includes the app name)
docker ps | grep garage

# Check status and get NODE_ID
docker exec <container-name> /garage status

# Assign storage capacity (adjust size as needed)
docker exec <container-name> /garage layout assign -z dc1 -c 10G <NODE_ID>

# Apply the layout
docker exec <container-name> /garage layout apply --version 1
```

### 6. Create Buckets and Keys

```bash
# Create a bucket
docker exec <container-name> /garage bucket create mybucket

# Create an access key
docker exec <container-name> /garage key create mykey

# Grant permissions
docker exec <container-name> /garage bucket allow --read --write --owner mybucket --key mykey

# Get key credentials (save these!)
docker exec <container-name> /garage key info mykey
```

### 7. Enable Website Hosting (Optional)

```bash
# Enable website mode for a bucket
docker exec <container-name> /garage bucket website --allow mybucket
```

## Using the S3 API

### Configure AWS CLI

```bash
aws configure
# AWS Access Key ID: <your-key-id>
# AWS Secret Access Key: <your-secret-key>
# Default region: garage
# Default output format: json
```

### Test Commands

```bash
# List buckets
aws --endpoint-url https://s3.anlak.es s3 ls

# Upload a file
aws --endpoint-url https://s3.anlak.es s3 cp myfile.txt s3://mybucket/

# List bucket contents
aws --endpoint-url https://s3.anlak.es s3 ls s3://mybucket/
```

### Using with other S3 clients

Use these settings:
- **Endpoint**: `https://s3.anlak.es`
- **Region**: `garage`
- **Path Style**: Both path-style and virtual-host-style work

## Accessing Static Files

Once website hosting is enabled for a bucket:

1. Upload your static files to the bucket
2. Access them at `https://<bucket-name>.files.anlak.es/`

Example:
```bash
# Upload index.html
aws --endpoint-url https://s3.anlak.es s3 cp index.html s3://mybucket/

# Access at: https://mybucket.files.anlak.es/
```

## Security Notes

1. Keep the admin API (port 3903) internal only - don't expose it publicly
2. Use strong, unique access keys for each application
3. Set environment variables securely in Dokploy (never commit secrets)

## Scaling (Optional)

For production with multiple nodes:
1. Change `replication_factor` to 2 or 3 in `garage.toml`
2. Deploy Garage on multiple servers with the same `rpc_secret`
3. Connect nodes: `garage node connect <node-id>@<ip>:3901`
4. Assign zones and capacity to each node

## Troubleshooting

```bash
# Check Garage status
docker exec <container-name> /garage status

# View layout
docker exec <container-name> /garage layout show

# List all buckets
docker exec <container-name> /garage bucket list

# List all keys
docker exec <container-name> /garage key list

# Check logs
docker logs <container-name>
```

## Volumes

Data is persisted in Docker volumes:
- `garage_meta` - Metadata (keep backups!)
- `garage_data` - Actual object data

To backup:
```bash
docker run --rm -v garage_meta:/data -v $(pwd):/backup alpine tar czf /backup/meta-backup.tar.gz /data
docker run --rm -v garage_data:/data -v $(pwd):/backup alpine tar czf /backup/data-backup.tar.gz /data
```
