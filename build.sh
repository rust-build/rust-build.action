#!/usr/bin/env bash

info() {
  echo "::info $@" >&2
}

error() {
  echo "::error file=entrypoint.sh:: $@" >&2
}

set -eux
PROJECT_ROOT="/rust/build/${GITHUB_REPOSITORY}"

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
"x86_64-unknown-linux-gnu") apk add --no-cache gcc ;;
"x86_64-apple-darwin")
# Cross-compile for mac-os
# https://wapl.es/rust/2019/02/17/rust-cross-compile-linux-to-macos.html 
apk add --no-cache gcc g++ clang cmake zlib-dev mpc1-dev mpfr-dev gmp-dev libxml2-dev openssl-dev
git clone https://github.com/tpoechtrager/osxcross
cd osxcross
curl -O https://s3.dockerproject.org/darwin/v2/MacOSX10.10.sdk.tar.xz
mv MacOSX10.10.sdk.tar.xz tarballs/
UNATTENDED=yes OSX_VERSION_MIN=10.7 OCDEBUG=1 ./build.sh
cd ..
mkdir -p /.cargo
touch /.cargo/config.toml
echo "[target.x86_64-apple-darwin]" >> /.cargo/config.toml
echo "linker = \"x86_64-apple-darwin14-clang\"" >> /.cargo/config.toml
echo "ar = \"x86_64-apple-darwin14-ar\"" >> /.cargo/config.toml
;;
"wasm32-wasi") ;;
"wasm32-unknown-emscripten") 
apk add --no-cache emscripten-fastcomp
mkdir -p /.cargo
touch /.cargo/config.toml 
echo "[target.wasm32-unknown-emscripten]" >> /.cargo/config.toml
echo "linker = \"/usr/lib/emscripten-fastcomp/bin/clang\"" >> /.cargo/config.toml
echo "ar = \"/usr/lib/emscripten-fastcomp/bin/llvm-ar\"" >> /.cargo/config.toml
;;
"arm-unknown-linux-gnueabi") apk add --no-cache gcc-arm-none-eabi ;;
*)
error "${RUSTTARGET} is not supported"
exit 1
;;
esac

BINARY=$(cargo read-manifest | jq ".name" -r)

info "Building $BINARY..."

if [ -x "./build.sh" ]; then
  OUTPUT=`./build.sh "${CMD_PATH}"`
else
  rustup target add "$RUSTTARGET"
  OPENSSL_LIB_DIR=/usr/lib64 OPENSSL_INCLUDE_DIR=/usr/include/openssl cargo build --release --target "$RUSTTARGET" --bins
  OUTPUT=$(find "target/${RUSTTARGET}/release/" -type f -name "${BINARY}" -name "${BINARY}.*" -executable | tr "\n" " ")
fi

info "Saving $OUTPUT..."

mv $OUTPUT "$PROJECT_ROOT"

OUTPUT_LIST=""
for f in $OUTPUT; do
  OUTPUT_LIST="$OUTPUT_LIST $(basename $f)"
done
echo "$OUTPUT_LIST"
