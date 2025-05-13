#!/usr/bin/env sh
set -eu

S3_BUCKET="${S3_BUCKET:?Need S3_BUCKET}"
DATE_HR="$(date '+%Y-%m-%d_%H-%M-%S')"    # human-readable, server local time

# read the mapping file supplied as a secret
URL_FILE="/run/secrets/pg_urls_cfg"

while IFS='=' read -r NAME URI; do
  [ -z "$NAME" ] && continue              # skip blank lines / comments

  echo "▶ dumping $NAME…"
  DUMP="/tmp/${NAME}.dump"
  pg_dump "$URI" --clean --if-exists --no-owner --no-acl -F c -f "$DUMP"

  ARCHIVE="/tmp/${NAME}_${DATE_HR}.tar.gz"
  tar -czf "$ARCHIVE" -C /tmp "${NAME}.dump" --remove-files

  KEY="$NAME/$NAME_$DATE_HR.tar.gz"       # S3 prefix per DB
  echo "⤴ uploading $KEY"
  aws s3 cp "$ARCHIVE" "s3://$S3_BUCKET/$KEY"
done < "$URL_FILE"

echo "🧹 pruning old backups (keep 3 each)…"
# for every DB prefix, list → sort newest-first → delete after 3rd
for NAME in $(awk -F= '{print $1}' "$URL_FILE"); do
  aws s3 ls "s3://$S3_BUCKET/$NAME/" \
    | awk '{print $4}' | sort -r \
    | awk 'NR>3' \
    | while read OLD; do
        echo "  deleting $OLD"
        aws s3 rm "s3://$S3_BUCKET/$OLD"
      done
done
