# Rust Release Binary Github Action

[![.github/workflows/build.yml](https://github.com/rust-build/rust-build.test/actions/workflows/build.yml/badge.svg)](https://github.com/rust-build/rust-build.test/actions/workflows/build.yml)
[![Lint](https://github.com/rust-build/rust-build.action/actions/workflows/linter.yml/badge.svg)](https://github.com/rust-build/rust-build.action/actions/workflows/linter.yml)

Automate publishing Rust build artifacts for GitHub releases through GitHub Actions (Based on [go-release.action](https://github.com/ngs/go-release.action))

For an example/template repo see [rust-build.test](https://github.com/rust-build/rust-build.test)

This action will only work when you release a project as it uploads the artifacts to the release.

## Environment variables
```bash
GITHUB_TOKEN      # Must be set to ${{ secrets.GITHUB_TOKEN }} - Allows uploading of artifacts to release
RUSTTARGET        # The rust target triple, see README for supported triples
EXTRA_FILES       # Space separated list of extra files to include in final output
SRC_DIR           # Relative path to the src dir (directory with Cargo.toml in) from root of project
ARCHIVE_TYPES     # Type(s) of archive(s) to create, e.g. "zip" (default) or "zip tar.gz"; supports: (zip, tar.[gz|bz2|xz|zst])
ARCHIVE_NAME      # Full name of archive to upload (you must specify file extension and change this if building multiple targets)
PRE_BUILD         # Path to script to run before build e.g. "pre.sh"
POST_BUILD        # Path to script to run after build e.g. "post.sh"
MINIFY            # If set to "true", the resulting binary will be stripped and compressed by UPX. ("false" by default)
TOOLCHAIN_VERSION # The rust toolchain version to use (see https://rust-lang.github.io/rustup/concepts/toolchains.html#toolchain-specification)
UPLOAD_MODE       # What method to use to upload compiled binaries, supported values: (release, none), default: release
```

## Examples

### Build windows and linux and upload as zip
```yml
# .github/workflows/release.yml

on:
  release:
    types: [created]

jobs:
  release:
    name: release ${{ matrix.target }}
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        target: [x86_64-pc-windows-gnu, x86_64-unknown-linux-musl]
    steps:
      - uses: actions/checkout@master
      - name: Compile and release
        uses: rust-build/rust-build.action@v1.3.2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          RUSTTARGET: ${{ matrix.target }}
          EXTRA_FILES: "README.md LICENSE"
```

### Build windows, linux and mac with native zip types
Will build native binaries for windows, linux and mac. Windows will upload as .zip, linux as .tar.gz, .tar.xz and
.tar.zst, and mac as .zip.
```yml
# .github/workflows/release.yml

on:
  release:
    types: [created]

jobs:
  release:
    name: release ${{ matrix.target }}
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        include:
          - target: x86_64-pc-windows-gnu
            archive: zip
          - target: x86_64-unknown-linux-musl
            archive: tar.gz tar.xz tar.zst
          - target: x86_64-apple-darwin
            archive: zip
    steps:
      - uses: actions/checkout@master
      - name: Compile and release
        uses: rust-build/rust-build.action@v1.3.2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          RUSTTARGET: ${{ matrix.target }}
          ARCHIVE_TYPES: ${{ matrix.archive }}
```

### Upload output as an artifact (or use with other steps)
```yml
# .github/workflows/build.yml
name: Build

on:
  push:
    branches: [main]

jobs:
  build:
    name: Build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@master
      - name: Compile
        id: compile
        uses: rust-build/rust-build.action@v1.3.2
        with:
          RUSTTARGET: x86_64-unknown-linux-musl
          UPLOAD_MODE: none
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: Binary
          path: |
            ${{ steps.compile.outputs.BUILT_ARCHIVE }}
            ${{ steps.compile.outputs.BUILT_CHECKSUM }}
```

_Many target triples do not work, I am working on adding more support_

## Supported targets
- `x86_64-pc-windows-gnu`
- `x86_64-unknown-linux-musl`
- `wasm32-wasi`
- `x86_64-apple-darwin`
