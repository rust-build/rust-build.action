FROM rust:1.60-alpine

LABEL "name"="Automate publishing Rust build artifacts for GitHub releases through GitHub Actions"
LABEL "version"="1.3.2"
LABEL "repository"="http://github.com/rust-build/rust-build.action"
LABEL "maintainer"="Douile <25043847+Douile@users.noreply.github.com>"

# Add regular dependencies
RUN apk add --no-cache curl=7.80.0-r1 jq=1.6-r1 git=2.34.2-r0 build-base=0.5-r2 bash=5.1.16-r0 \
  zip=3.0-r9 upx=3.96-r1

# Add windows dependencies
RUN apk add --no-cache mingw-w64-gcc=11.2.0-r0

# Add emscripten dependencies
RUN apk add --no-cache emscripten-fastcomp=1.40.1-r1

# Add apple dependencies
RUN apk add --no-cache clang=12.0.1-r1 cmake=3.21.3-r0 libxml2-dev=2.9.13-r0 \
  openssl-dev=1.1.1n-r0 fts-dev=1.2.7-r1 bsd-compat-headers=0.7.2-r3 xz=5.2.5-r1
RUN git clone https://github.com/tpoechtrager/osxcross /opt/osxcross
RUN curl -Lo /opt/osxcross/tarballs/MacOSX10.10.sdk.tar.xz "https://s3.dockerproject.org/darwin/v2/MacOSX10.10.sdk.tar.xz"
RUN ["/bin/bash", "-c", "cd /opt/osxcross && UNATTENDED=yes OSX_VERSION_MIN=10.8 ./build.sh"]

COPY entrypoint.sh /entrypoint.sh
COPY build.sh /build.sh

RUN chmod +x /entrypoint.sh /build.sh

ENTRYPOINT ["/entrypoint.sh"]
