# Rust Release Binary Github Action

Automate publishing Rust build artifacts for GitHub releases through GitHub Actions (Based on [go-release.action](https://github.com/ngs/go-release.action))

For an example/template repo see [rust-build.test](https://github.com/rust-build/rust-build.test)

Example
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
        target: [x86_64-pc-windows-gnu, x86_64-unknown-linux-musl, x86_64-unknown-linux-gnu]
    steps:
      - uses: actions/checkout@master
      - name: Compile and release
        uses: rust-build/rust-build.action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          RUSTTARGET: ${{ matrix.target }}
          EXTRA_FILES: "README.md LICENSE"
```

_Many target triples do not work, I am working on adding more support_

Supported targets
- `x86_64-pc-windows-gnu`
- `x86_64-unkown-linux-musl`
- `x86_64-unkown-linux-gnu`
- `wasm32-wasi` 
