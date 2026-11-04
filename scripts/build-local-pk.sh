#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
toolchain_root="$project_root/toolchain/usr"
pk_root="$project_root/riscv-pk"
specs_file="$project_root/toolchain/picolibc-pk.specs"
configure_specs_file="$project_root/toolchain/picolibc-local.specs"

sed "s#/usr/lib/picolibc#$toolchain_root/lib/picolibc#g" \
    "$toolchain_root/lib/picolibc/riscv64-unknown-elf/picolibc.specs" > "$configure_specs_file"
sed 's/%{!T:-Tpicolibc.ld}//g' "$configure_specs_file" > "$specs_file"

cross_cc="$toolchain_root/bin/riscv64-unknown-elf-gcc -B$toolchain_root/lib/riscv64-unknown-elf/bin/ -specs=$specs_file"
configure_cc="$toolchain_root/bin/riscv64-unknown-elf-gcc -B$toolchain_root/lib/riscv64-unknown-elf/bin/ -specs=$configure_specs_file"
cross_cxx="$toolchain_root/bin/riscv64-unknown-elf-g++ -B$toolchain_root/lib/riscv64-unknown-elf/bin/"
mkdir -p "$pk_root/build"
(
    cd "$pk_root/build"
    PATH="$toolchain_root/bin:$PATH" CC="$configure_cc" CXX="$cross_cxx" \
        ../configure --prefix="$project_root/install" --host=riscv64-unknown-elf
    PATH="$toolchain_root/bin:$PATH" make -s -j4 pk CC="$cross_cc"
    mkdir -p "$project_root/install/riscv64-unknown-elf/bin"
    install -m 755 pk "$project_root/install/riscv64-unknown-elf/bin/pk"
)
