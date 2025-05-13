FROM alpine:3.20

RUN apk add --no-cache postgresql-client tar gzip aws-cli jq

# copy the backup script in (see next section)
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
