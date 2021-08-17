#!/usr/bin/env bash

info() {
  echo "::info $*" >&2
}

error() {
  echo "::error file=entrypoint.sh:: $*" >&2
}

set -eu
PROJECT_ROOT="/rust/build/${GITHUB_REPOSITORY}"
OUTPUT_DIR="$1"

mkdir -p "$PROJECT_ROOT"
rmdir "$PROJECT_ROOT"
ln -s "$GITHUB_WORKSPACE" "$PROJECT_ROOT"
cd "$PROJECT_ROOT"

if [ -z "${SRC_DIR+0}" ]; then
  info "No SRC_DIR is set, using repo base dir"
else
  info "Switching to src dir \"$SRC_DIR\""
  cd "$SRC_DIR"
fi

info "Installing additional linkers"
case ${RUSTTARGET} in
"x86_64-pc-windows-gnu") ;;

"x86_64-unknown-linux-musl") ;;

"x86_64-unknown-linux-gnu") 
error "x86_64-unknown-linux-gnu is not supported: please use x86_64-unknown-linux-musl for a statically linked c library"
exit 1
;;

"wasm32-wasi") ;;
"wasm32-unknown-emscripten") 
mkdir -p /.cargo
cat > /.cargo/config.toml << EOF
[target.wasm32-unknown-emscripten]
linker = "/usr/lib/emscripten-fastcomp/bin/clang"
ar = "/usr/lib/emscripten-fastcomp/bin/llvm-ar"
EOF
;;

"x86_64-apple-darwin")
mkdir -p /.cargo
cat > /.cargo/config.toml << EOF
[target.x86_64-apple-darwin]
linker = "/opt/osxcross/target/bin/x86_64-apple-darwin14-clang"
ar = "/opt/osxcross/target/bin/x86_64-apple-darwin14-ar"
EOF
;;

*)
error "${RUSTTARGET} is not supported"
exit 1
;;
esac

BINARIES="$(cargo read-manifest | jq -r ".targets[] | select(.kind[] | contains(\"bin\")) | .name")"

OUTPUT_LIST=""
for BINARY in $BINARIES; do
  info "Building $BINARY..."

  if [ -x "./build.sh" ]; then
    OUTPUT=$(./build.sh "${CMD_PATH}" "${OUTPUT_DIR}")
  else
    rustup target add "$RUSTTARGET"
    OPENSSL_LIB_DIR=/usr/lib64 OPENSSL_INCLUDE_DIR=/usr/include/openssl CARGO_TARGET_DIR="./target" cargo build --release --target "$RUSTTARGET" --bin "$BINARY"
    OUTPUT=$(find "target/${RUSTTARGET}/release/" -maxdepth 1 -type f -executable \( -name "${BINARY}" -o -name "${BINARY}.*" \) -print0 | xargs -0)
  fi

  if [ -z "$OUTPUT" ]; then
    error "Unable to find output"
  fi

  info "Saving $OUTPUT..."

  # shellcheck disable=SC2086
  mv $OUTPUT "$OUTPUT_DIR" || error "Unable to copy binary"

  for f in $OUTPUT; do
    OUTPUT_LIST="$OUTPUT_LIST $(basename "$f")"
  done
done
echo "$OUTPUT_LIST"
