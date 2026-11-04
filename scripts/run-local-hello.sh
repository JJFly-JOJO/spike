#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
toolchain_root="$project_root/toolchain/usr"
picolibc_dir="$toolchain_root/lib/picolibc/riscv64-unknown-elf"
specs_file="$project_root/toolchain/picolibc-pk.specs"

# The extracted Ubuntu package uses /usr paths. Point them at this project,
# and let the default linker place the user program for PK.
sed -e "s#/usr/lib/picolibc#$toolchain_root/lib/picolibc#g" \
    -e 's/%{!T:-Tpicolibc.ld}//g' \
    "$picolibc_dir/picolibc.specs" > "$specs_file"

"$toolchain_root/bin/riscv64-unknown-elf-gcc" \
    -B"$toolchain_root/lib/riscv64-unknown-elf/bin/" \
    -specs="$specs_file" -nostartfiles -static -mcmodel=medany \
    "$project_root/examples/hello.c" \
    "$project_root/examples/picolibc-pk-io.c" \
    "$project_root/examples/picolibc-pk-start.S" \
    -o "$project_root/examples/hello-picolibc-pk.elf"

"$project_root/install/bin/spike" -m64 \
    "$project_root/install/riscv64-unknown-elf/bin/pk" \
    "$project_root/examples/hello-picolibc-pk.elf"
