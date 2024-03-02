FROM rust:1.76.0-alpine3.19

LABEL "name"="Automate publishing Rust build artifacts for GitHub releases through GitHub Actions"
LABEL "version"="1.4.5"
LABEL "repository"="http://github.com/rust-build/rust-build.action"
LABEL "maintainer"="Douile <25043847+Douile@users.noreply.github.com>"

# Add regular dependencies
RUN apk add --no-cache curl jq git build-base bash zip tar xz zstd upx

# Add windows dependencies
RUN apk add --no-cache mingw-w64-gcc

# Add apple dependencies
RUN apk add --no-cache clang cmake libxml2-dev openssl-dev musl-fts-dev bsd-compat-headers python3
RUN git clone https://github.com/tpoechtrager/osxcross /opt/osxcross
RUN curl -Lo /opt/osxcross/tarballs/MacOSX10.10.sdk.tar.xz "https://github.com/joseluisq/macosx-sdks/releases/download/10.10/MacOSX10.10.sdk.tar.xz"
RUN curl -Lo /opt/osxcross/tarballs/MacOSX12.3.sdk.tar.xz "https://github.com/joseluisq/macosx-sdks/releases/download/12.3/MacOSX12.3.sdk.tar.xz"
RUN ["/bin/bash", "-c", "cd /opt/osxcross && TARGET_DIR=/opt/osxcross/target10_10 UNATTENDED=yes SDK_VERSION=10.10 ./build.sh"]
RUN ["/bin/bash", "-c", "cd /opt/osxcross && TARGET_DIR=/opt/osxcross/target12_3 UNATTENDED=yes SDK_VERSION=12.3 ./build.sh"]

COPY entrypoint.sh /entrypoint.sh
COPY build.sh /build.sh
COPY common.sh /common.sh

RUN chmod 555 /entrypoint.sh /build.sh /common.sh

ENTRYPOINT ["/entrypoint.sh"]
