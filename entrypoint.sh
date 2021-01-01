#!/usr/bin/env bash

set -eux

if [ -z "${CMD_PATH+x}" ]; then
  echo "::warning file=entrypoint.sh::CMD_PATH not set"
  export CMD_PATH=""
fi

echo "::info Installing additional linkers"
case ${RUSTTARGET} in
"x86_64-pc-windows-gnu") apk add --no-cache mingw-w64-gcc ;;
"x86_64-unknown-linux-musl") ;;
"x86_64-unknown-linux-gnu") apk add --no-cache gcc ;;
"x86_64-apple-darwin") apk add --no-cache gcc ;;
*)
echo "::error file=entrypoint.sh::${RUSTTARGET} is not supported" ;;
# exit 1
esac

FILE_LIST=`/build.sh`

EVENT_DATA=$(cat $GITHUB_EVENT_PATH)
echo $EVENT_DATA | jq .
UPLOAD_URL=$(echo $EVENT_DATA | jq -r .release.upload_url)
UPLOAD_URL=${UPLOAD_URL/\{?name,label\}/}
RELEASE_NAME=$(echo $EVENT_DATA | jq -r .release.tag_name)
PROJECT_NAME=$(basename $GITHUB_REPOSITORY)
NAME="${NAME:-${PROJECT_NAME}_${RELEASE_NAME}}_${RUSTTARGET}"

if [ -z "${EXTRA_FILES+x}" ]; then
  echo "::warning file=entrypoint.sh::EXTRA_FILES not set"
fi

FILE_LIST="${FILE_LIST} ${EXTRA_FILES}"

FILE_LIST=$(echo "${FILE_LIST}" | awk '{$1=$1};1')

ARCHIVE="tmp.zip"
echo "::info Packing files: $FILE_LIST"
zip -9r $ARCHIVE ${FILE_LIST}

CHECKSUM=$(sha256sum ${ARCHIVE} | cut -d ' ' -f 1)

curl \
  -X POST \
  --data-binary @${ARCHIVE} \
  -H 'Content-Type: application/octet-stream' \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "${UPLOAD_URL}?name=${NAME}.${ARCHIVE/tmp./}"

curl \
  -X POST \
  --data $CHECKSUM \
  -H 'Content-Type: text/plain' \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "${UPLOAD_URL}?name=${NAME}_checksum.txt"
