FROM alpine:3.20

ARG PG_VERSION=16
LABEL org.opencontainers.image.description="PostgreSQL ${PG_VERSION} backup tool for AWS S3"

RUN apk add --no-cache postgresql${PG_VERSION}-client tar gzip aws-cli jq

# copy the backup script in (see next section)
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
