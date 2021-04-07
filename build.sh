#!/usr/bin/env bash

info() {
  echo "::info $@" >&2
}

error() {
  echo "::error file=entrypoint.sh:: $@" >&2
}

set -eux
PROJECT_ROOT="/rust/build/${GITHUB_REPOSITORY}"
OUTPUT_DIR="$1"

mkdir -p $PROJECT_ROOT
rmdir $PROJECT_ROOT
ln -s $GITHUB_WORKSPACE $PROJECT_ROOT
cd $PROJECT_ROOT

if [ "" != "$SRC_DIR" ]; then
  info "Switching to src dir \"$SRC_DIR\""
  cd $SRC_DIR
fi

info "Installing additional linkers"
case ${RUSTTARGET} in
"x86_64-pc-windows-gnu") apk add --no-cache mingw-w64-gcc ;;

"x86_64-unknown-linux-musl") ;;

"x86_64-unknown-linux-gnu") 
error "x86_64-unknown-linux-gnu is not supported: please use x86_64-unknown-linux-musl for a statically linked c library"
exit 1
;;

"wasm32-wasi") ;;
"wasm32-unknown-emscripten") 
apk add --no-cache emscripten-fastcomp
mkdir -p /.cargo
cat > /.cargo/config.toml << EOF
[target.wasm32-unknown-emscripten]
linker = "/usr/lib/emscripten-fastcomp/bin/clang"
ar = "/usr/lib/emscripten-fastcomp/bin/llvm-ar"
EOF
;;

*)
error "${RUSTTARGET} is not supported"
exit 1
;;
esac

BINARY=$(cargo read-manifest | jq ".name" -r)

info "Building $BINARY..."

if [ -x "./build.sh" ]; then
  OUTPUT=`./build.sh "${CMD_PATH}" "${OUTPUT_DIR}"`
else
  rustup target add "$RUSTTARGET"
  OPENSSL_LIB_DIR=/usr/lib64 OPENSSL_INCLUDE_DIR=/usr/include/openssl cargo build --release --target "$RUSTTARGET" --bins
  OUTPUT=$(find "target/${RUSTTARGET}/release/" -maxdepth 1 -type f -executable \( -name "${BINARY}" -o -name "${BINARY}.*" \) | tr "\n" " ")
fi

info "Saving $OUTPUT..."

mv $OUTPUT "$OUTPUT_DIR" || error "Unable to copy binary"

OUTPUT_LIST=""
for f in $OUTPUT; do
  OUTPUT_LIST="$OUTPUT_LIST $(basename $f)"
done
echo "$OUTPUT_LIST"
