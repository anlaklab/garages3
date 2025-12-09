# Use Alpine as base to have shell for env substitution
FROM alpine:3.19

# Install envsubst (from gettext package)
RUN apk add --no-cache gettext

# Copy garage binary from official image
COPY --from=dxflrs/garage:v2.1.0 /garage /garage

# Copy configuration template
COPY garage.toml /etc/garage.toml.template

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create data directories
RUN mkdir -p /var/lib/garage/meta /var/lib/garage/data

# Expose ports
# 3900 - S3 API (s3.anlak.es)
# 3901 - RPC (internal)
# 3902 - Web/Static hosting
# 3903 - Admin API
EXPOSE 3900 3901 3902 3903

ENTRYPOINT ["/entrypoint.sh"]
