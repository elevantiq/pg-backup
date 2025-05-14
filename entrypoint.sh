#!/usr/bin/env sh
set -eu

S3_BUCKET="${S3_BUCKET:?Need S3_BUCKET}"
PG_URLS="${PG_URLS:?Need PG_URLS as comma-separated list of NAME=URI pairs}"
BACKUPS_TO_KEEP="${BACKUPS_TO_KEEP:-3}"  # default to 3 if not set
DATE_HR="$(date '+%Y-%m-%d_%H-%M-%S')"    # human-readable, server local time

# Process each database URL from the comma-separated list
echo "$PG_URLS" | tr ',' '\n' | while IFS='=' read -r NAME URI; do
  [ -z "$NAME" ] && continue              # skip blank lines

  echo "▶ dumping $NAME…"
  DUMP="/tmp/${NAME}.dump"
  pg_dump "$URI" --clean --if-exists --no-owner --no-acl -F c -f "$DUMP"

  ARCHIVE="/tmp/${NAME}_${DATE_HR}.tar.gz"
  tar -czf "$ARCHIVE" -C /tmp "${NAME}.dump" --remove-files

  KEY="$NAME/${NAME}_${DATE_HR}.tar.gz"       # S3 prefix per DB
  echo "⤴ uploading $KEY"
  aws s3 cp "$ARCHIVE" "s3://$S3_BUCKET/$KEY"
done

echo "🧹 pruning old backups (keep $BACKUPS_TO_KEEP each)…"
# for every DB prefix, list → sort newest-first → delete after BACKUPS_TO_KEEP
echo "$PG_URLS" | tr ',' '\n' | cut -d= -f1 | while read NAME; do
  [ -z "$NAME" ] && continue              # skip blank lines
  aws s3 ls "s3://$S3_BUCKET/$NAME/" \
    | awk '{print $4}' | sort -r \
    | awk "NR>$BACKUPS_TO_KEEP" \
    | while read OLD; do
        echo "  deleting $NAME/$OLD"
        aws s3 rm "s3://$S3_BUCKET/$NAME/$OLD"
      done
done

echo "✅ Backup completed successfully at $(date '+%Y-%m-%d %H:%M:%S')"