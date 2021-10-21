FROM rust:1.55-alpine
MAINTAINER Douile <25043847+Douile@users.noreply.github.com>

LABEL "com.github.actions.name"="Rust Release binary"
LABEL "com.github.actions.description"="Automate publishing Rust build artifacts for GitHub releases through GitHub Actions"

LABEL "name"="Automate publishing Rust build artifacts for GitHub releases through GitHub Actions"
LABEL "version"="1.2.1"
LABEL "repository"="http://github.com/Douile/rust-release.action"
LABEL "maintainer"="Douile <25043847+Douile@users.noreply.github.com>"

# Add regular dependencies
RUN apk add --no-cache curl jq git build-base bash zip

# Add windows dependencies
RUN apk add --no-cache mingw-w64-gcc

# Add emscripten dependencies
RUN apk add --no-cache emscripten-fastcomp

# Add apple dependencies
RUN apk add --no-cache clang cmake libxml2-dev openssl-dev fts-dev bsd-compat-headers xz
RUN git clone https://github.com/tpoechtrager/osxcross /opt/osxcross
RUN curl -Lo /opt/osxcross/tarballs/MacOSX10.10.sdk.tar.xz "https://s3.dockerproject.org/darwin/v2/MacOSX10.10.sdk.tar.xz"
RUN ["/bin/bash", "-c", "cd /opt/osxcross && UNATTENDED=yes OSX_VERSION_MIN=10.8 ./build.sh"]

ADD entrypoint.sh ./entrypoint.sh
ADD build.sh ./build.sh

RUN chmod +x /entrypoint.sh /build.sh

ENTRYPOINT ["/entrypoint.sh"]
