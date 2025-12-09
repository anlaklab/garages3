FROM dxflrs/garage:v2.1.0

# Copy configuration template
COPY garage.toml /etc/garage.toml.template

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports
# 3900 - S3 API (s3.anlak.es)
# 3901 - RPC (internal)
# 3902 - Web/Static hosting
# 3903 - Admin API
EXPOSE 3900 3901 3902 3903

# Environment variables (set in Dokploy)
ENV RPC_SECRET=""
ENV ADMIN_TOKEN=""

ENTRYPOINT ["/entrypoint.sh"]
