#!/usr/bin/env bash

set -eu

if [ -z "${CMD_PATH+x}" ]; then
  export CMD_PATH=""
fi

OUTPUT_DIR="/output"
mkdir -p "$OUTPUT_DIR"


if ! FILE_LIST=$(/build.sh "$OUTPUT_DIR"); then
  echo "::error file=entrypoint.sh::Build failed" >&2
  exit 1
fi

EVENT_DATA=$(cat "$GITHUB_EVENT_PATH")
echo "$EVENT_DATA" | jq .
UPLOAD_URL=$(echo "$EVENT_DATA" | jq -r .release.upload_url)
if [ "$UPLOAD_URL" = "null" ]; then
  echo "::error file=entrypoint.sh::The event provided did not contain an upload URL, this workflow can only be used with the release event." >&2
  exit 1
fi
UPLOAD_URL=${UPLOAD_URL/\{?name,label\}/}
RELEASE_NAME=$(echo "$EVENT_DATA" | jq -r .release.tag_name)
PROJECT_NAME=$(basename "$GITHUB_REPOSITORY")
NAME="${NAME:-${PROJECT_NAME}_${RELEASE_NAME}}_${RUSTTARGET}"
ARCHIVE_TYPES="${ARCHIVE_TYPES:-"zip"}"
EXTRA_FILES="${EXTRA_FILES:-""}"

if [ -z "${EXTRA_FILES+x}" ]; then
  echo "::warning file=entrypoint.sh::EXTRA_FILES not set"
else
  for file in $(echo -n "${EXTRA_FILES}" | tr " " "\n"); do
    cp "$file" "$OUTPUT_DIR"
  done
fi

cd "$OUTPUT_DIR"

if [ -n "${EXTRA_FILES+0}" ]; then
  FILE_LIST="${FILE_LIST} ${EXTRA_FILES}"
fi

FILE_LIST=$(echo "${FILE_LIST}" | awk '{$1=$1};1')

echo "::info::Packing files: $FILE_LIST"

for ARCHIVE_TYPE in $ARCHIVE_TYPES; do
  ARCHIVE="tmp.${ARCHIVE_TYPE}"

  # shellcheck disable=SC2086
  case $ARCHIVE_TYPE in
    "zip")
      zip -9r $ARCHIVE ${FILE_LIST}
    ;;

    "tar"|"tar.gz"|"tar.bz2"|"tar.xz")
      tar caf $ARCHIVE ${FILE_LIST}
    ;;

    *)
      echo "::error file=entrypoint.sh::The given archive type '${ARCHIVE_TYPE}' is not supported; please choose one of 'zip' or 'tar.gz'"
      continue
  esac

  CHECKSUM=$(sha256sum "${ARCHIVE}" | cut -d ' ' -f 1)

  curl \
    -X POST \
    --data-binary @"${ARCHIVE}" \
    -H 'Content-Type: application/octet-stream' \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "${UPLOAD_URL}?name=${NAME}.${ARCHIVE/tmp./}"

  curl \
    -X POST \
    --data "$CHECKSUM" \
    -H 'Content-Type: text/plain' \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "${UPLOAD_URL}?name=${NAME}.${ARCHIVE/tmp./}.sha256sum"
done
