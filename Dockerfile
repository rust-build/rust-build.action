FROM rust:1.64-alpine

LABEL "name"="Automate publishing Rust build artifacts for GitHub releases through GitHub Actions"
LABEL "version"="1.4.0"
LABEL "repository"="http://github.com/rust-build/rust-build.action"
LABEL "maintainer"="Douile <25043847+Douile@users.noreply.github.com>"

# Add regular dependencies
RUN apk add --no-cache curl=7.83.1-r4 jq=1.6-r1 git=2.36.3-r0 build-base=0.5-r3 bash=5.1.16-r2 \
  zip=3.0-r9 tar=1.34-r0 xz=5.2.5-r1 zstd=1.5.2-r1 upx=3.96-r1

# Add windows dependencies
RUN apk add --no-cache mingw-w64-gcc=11.3.0-r0

# Add apple dependencies
RUN apk add --no-cache clang=13.0.1-r1 cmake=3.23.1-r0 libxml2-dev=2.9.14-r2 \
  openssl-dev=1.1.1q-r0 fts-dev=1.2.7-r1 bsd-compat-headers=0.7.2-r3
RUN git clone https://github.com/tpoechtrager/osxcross /opt/osxcross
RUN curl -Lo /opt/osxcross/tarballs/MacOSX10.10.sdk.tar.xz "https://s3.dockerproject.org/darwin/v2/MacOSX10.10.sdk.tar.xz"
RUN ["/bin/bash", "-c", "cd /opt/osxcross && UNATTENDED=yes OSX_VERSION_MIN=10.8 ./build.sh"]

COPY entrypoint.sh /entrypoint.sh
COPY build.sh /build.sh

RUN chmod +x /entrypoint.sh /build.sh

ENTRYPOINT ["/entrypoint.sh"]
