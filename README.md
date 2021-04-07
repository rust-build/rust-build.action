# Rust Release Binary Github Action

Automate publishing Rust build artifacts for GitHub releases through GitHub Actions (Based on [go-release.action](https://github.com/ngs/go-release.action))

For an example/template repo see [rust-build.test](https://github.com/rust-build/rust-build.test)

## Environment variables
```bash
GITHUB_TOKEN  # Must be set to ${{ secrets.GITHUB_TOKEN }} - Allows uploading of artifacts to release
RUSTTARGET    # The rust target triple, see README for supported triples
EXTRA_FILES   # Space seperated list of extra files to include in final output
SRC_DIR       # Relative path to the src dir (directory with Cargo.toml in) from root of project
```

## Example
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
        uses: rust-build/rust-build.action@latest
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          RUSTTARGET: ${{ matrix.target }}
          EXTRA_FILES: "README.md LICENSE"
```

_Many target triples do not work, I am working on adding more support_

## Supported targets
- `x86_64-pc-windows-gnu`
- `x86_64-unkown-linux-musl`
- `wasm32-wasi` 
