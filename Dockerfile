FROM rust:1.46-alpine3.11
MAINTAINER Douile <25043847+Douile@users.noreply.github.com>

LABEL "com.github.actions.name"="Rust Release binary"
LABEL "com.github.actions.description"="Automate publishing Rust build artifacts for GitHub releases through GitHub Actions"

LABEL "name"="Automate publishing Rust build artifacts for GitHub releases through GitHub Actions"
LABEL "version"="0.1.0"
LABEL "repository"="http://github.com/Douile/rust-release.action"

LABEL "maintainer"="Douile <25043847+Douile@users.noreply.github.com>"

RUN apk add --no-cache curl jq git build-base bash musl-dev openssl

ADD entrypoint.sh ./entrypoint.sh
ADD build.sh ./build.sh
ENTRYPOINT ["/entrypoint.sh"]
