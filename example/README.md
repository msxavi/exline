# Exline Hello

A minimal "Exline" project plus a Rust prototype compiler `exlc`.

## Quick start

```bash
# 1) Build the exlc tool
cd example/tools/exlc
cargo build --release

# 2) From repo root, compile the Exline program
cd ../../
./tools/exlc/target/release/exlc build

# 3) Run the compiled binary
./target/hello

# Or do both (build+run):
./tools/exlc/target/release/exlc run
```

## What works (MVP of the MVP)
- `def main ... end` as the entry point.
- `print "literal"` for string output.
- (Soon) string interpolation, variables, simple expressions.

## How it works
- `exlc` translates `src/main.exl` to Rust (`target/gen/main.rs`), then invokes `rustc`.
- Output binary is `target/hello` by default.
