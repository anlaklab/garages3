# Use Debian slim for glibc compatibility
FROM debian:bookworm-slim

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    supervisor curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy garage binary from official image
COPY --from=dxflrs/garage:v2.1.0 /garage /garage

# Download garage-webui from GitHub releases
RUN curl -fSL -o /garage-webui https://github.com/khairul169/garage-webui/releases/download/1.1.0/garage-webui-v1.1.0-linux-amd64 \
    && chmod +x /garage-webui

# Copy configuration template
COPY garage.toml /etc/garage.toml.template

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy supervisord config
COPY supervisord.conf /etc/supervisord.conf

# Create data directories
RUN mkdir -p /var/lib/garage/meta /var/lib/garage/data

# Expose ports
# 3900 - S3 API (s3.anlak.es)
# 3901 - RPC (internal)
# 3902 - Web/Static hosting
# 3903 - Admin API
# 3909 - WebUI (files.anlak.es)
EXPOSE 3900 3901 3902 3903 3909

ENTRYPOINT ["/entrypoint.sh"]
