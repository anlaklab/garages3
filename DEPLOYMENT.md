# Garage S3 Deployment Guide for Dokploy

## Overview

This setup deploys Garage S3-compatible storage with:
- **s3.anlak.es** - S3 API endpoint (port 3900)
- **files.anlak.es** - Admin Web UI (port 3909)

## Files Structure

```
├── docker-compose.yml    # Docker compose configuration
├── garage.toml           # Garage configuration
├── .env                  # Environment variables (admin token)
├── .env.example          # Environment template
└── setup.sh              # Initial setup script
```

## Dokploy Deployment Steps

### 1. Create a New Project in Dokploy

1. Go to Dokploy dashboard
2. Create a new project (e.g., "garage-s3")

### 2. Deploy Using Docker Compose

1. In the project, select "Add Service" → "Docker Compose"
2. Upload these files:
   - `docker-compose.yml`
   - `garage.toml`
   - `.env`

### 3. Configure Domains in Dokploy

Add two domains/routes:

#### Route 1: S3 API
- **Domain**: `s3.anlak.es`
- **Port**: `3900`
- **SSL**: Enable (Let's Encrypt)

#### Route 2: Admin Web UI
- **Domain**: `files.anlak.es`
- **Port**: `3909`
- **SSL**: Enable (Let's Encrypt)

### 4. Deploy and Initialize

1. Deploy the service in Dokploy
2. SSH into your server or use Dokploy's terminal
3. Run the setup script:

```bash
# If using the setup script directly
./setup.sh

# Or manually execute:
docker exec garage garage status
docker exec garage garage layout assign -z dc1 -c 10G <NODE_ID>
docker exec garage garage layout apply --version 1
```

### 5. Create Buckets and Keys

```bash
# Create a bucket
docker exec garage garage bucket create mybucket

# Create an access key
docker exec garage garage key create mykey

# Grant permissions
docker exec garage garage bucket allow --read --write --owner mybucket --key mykey

# Get key credentials
docker exec garage garage key info mykey
```

### 6. Enable Website Hosting (for files.anlak.es)

```bash
# Enable website mode for a bucket
docker exec garage garage bucket website --allow mybucket
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

## Using the Admin Web UI

Once deployed, access the Admin Web UI at `https://files.anlak.es`

The WebUI allows you to:
- View cluster status and node information
- Create and manage buckets
- Create and manage access keys
- Browse and manage objects in buckets
- Configure bucket permissions

## Security Notes

1. Keep the admin API (port 3903) internal only - don't expose it publicly
2. Use strong, unique access keys for each application
3. The `.env` file contains sensitive tokens - keep it secure

## Scaling (Optional)

For production with multiple nodes:
1. Change `replication_factor` to 2 or 3 in `garage.toml`
2. Deploy Garage on multiple servers with the same `rpc_secret`
3. Connect nodes: `garage node connect <node-id>@<ip>:3901`
4. Assign zones and capacity to each node

## Troubleshooting

```bash
# Check Garage status
docker exec garage garage status

# View layout
docker exec garage garage layout show

# List all buckets
docker exec garage garage bucket list

# List all keys
docker exec garage garage key list

# Check logs
docker logs garage

# Check WebUI logs
docker logs garage-webui
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
