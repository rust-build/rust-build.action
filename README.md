# Rust Release Binary Github Action

Automate publishing Rust build artifacts for GitHub releases through GitHub Actions (Based on [go-release.action](https://github.com/ngs/go-release.action))

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
        target: [x86_64-pc-windows-gnu, x86_64-unknown-linux-gnu, x86_64-apple-darwin]
    steps:
      - uses: actions/checkout@master
      - name: Compile and release
        uses: Douile/rust-build.action@v0.1.22
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          RUSTTARGET: ${{ matrix.target }}
          EXTRA_FILES: "README.md LICENSE"
```
_Some target triples may not work_
