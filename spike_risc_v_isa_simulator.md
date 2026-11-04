# Spike (RISC-V ISA Simulator) 学习与实践指南

本文档旨在提供一个从零开始掌握 RISC-V 黄金参考模拟器 Spike 的完整学习路径。内容涵盖环境搭建、基础运行、交互式调试、操作系统启动以及源码定制。

---

## 阶段一：环境搭建与基础概念

要让 Spike 跑起来，我们需要准备“三剑客”：交叉编译器（Toolchain）、模拟器（Spike）和代理内核（Proxy Kernel, PK）。

### 1.1 准备基础环境 (以 Ubuntu 20.04/22.04 或 WSL2 为例)
首先安装必要的依赖包。Spike 源码还依赖 Boost 和 Expat 的开发包：
```bash
sudo apt-get update
sudo apt-get install git build-essential autoconf automake autotools-dev libtool \
    device-tree-compiler libboost-regex-dev libboost-system-dev libexpat1-dev \
    zlib1g-dev bison flex
```

先确认可以访问 GitHub 和 Ubuntu 软件源，再安装依赖。若在 WSL 中使用代理，需要确保 WSL 内的代理地址可连接；需要系统级安装权限时，在正常的 WSL 终端中运行 `sudo`。

### 1.2 安装 RISC-V 交叉编译工具链
*提示：完整编译工具链需要数小时及 10GB+ 硬盘空间。为了快速上手，建议直接使用 Ubuntu 仓库中预编译的工具链。以下统一使用 GNU/Linux 交叉工具链，与后文的 PK 配置保持一致。*
```bash
sudo apt-get install gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu libc6-dev-riscv64-cross
riscv64-linux-gnu-gcc --version
```

也可以使用 `riscv64-unknown-elf` 裸机工具链，但须另配可用的目标 C 库。Ubuntu 22.04 的 `gcc-riscv64-unknown-elf` 包单独安装后没有 `stdio.h`，不能直接编译下文的 `printf` 示例。选用该工具链时，PK 的 `--host`、示例中的编译器名称也要一起改为 `riscv64-unknown-elf`。自行从源码编译可参考 [riscv-gnu-toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain)。

### 1.3 编译安装 Spike (riscv-isa-sim)
在本仓库根目录初始化两个子模块并编译 Spike。子模块来自个人 fork 的 `develop` 分支，本仓库固定了已验证的提交；以下将安装结果放在当前项目目录，避免依赖系统级安装权限：
```bash
git submodule update --init --recursive
cd riscv-isa-sim
mkdir -p build && cd build
../configure --prefix="$(cd ../.. && pwd)/install"
make -j4
make install
cd ../..
export PATH="$(pwd)/install/bin:$PATH"
```
如果 `git submodule update` 失败，先检查网络连接并重试。子模块目录为空时不能继续编译。验证安装：输入 `spike --help`，应看到版本和使用说明。后续打开新终端时需重新设置上述 `PATH`，或者将其加入 shell 配置文件。

### 1.4 编译安装 Proxy Kernel (PK)
PK 用于接管 C 语言程序中的系统调用（如 `printf`），将其转发给宿主机操作系统。
```bash
cd riscv-pk
mkdir -p build && cd build
# --host 必须与 1.2 节选用的交叉编译器前缀一致
../configure --prefix="$(cd ../.. && pwd)/install" --host=riscv64-linux-gnu
make -j4 pk
mkdir -p ../../install/riscv64-linux-gnu/bin
install -m 755 pk ../../install/riscv64-linux-gnu/bin/pk
cd ../..
find install -type f -name pk
```

PK 会安装到 `install/riscv64-linux-gnu/bin/pk`，也可以使用上面的 `find` 命令确认实际位置。这里单独编译 `pk`，不需要同时编译可选的 `bbl`。运行 Spike 时传入这个路径，避免假定 `pk` 已在 `PATH` 中。

本仓库引用的 `riscv-pk` fork 的 `develop` 分支已包含 CSR 兼容修改：用 `0x30a` 和 `0x10a` 分别代替旧版 binutils 不识别的 `menvcfg` 和 `senvcfg` 名称。因此按上述步骤直接构建即可。`patches/riscv-pk-ubuntu22-binutils.patch` 保留为相对上游提交 `9c61d29` 的差异参考，已使用本仓库子模块的源码时不要重复应用。

本项目当前 WSL2 环境也准备了无需系统级安装的版本：Spike 位于 `install/bin/spike`，PK 位于 `install/riscv64-unknown-elf/bin/pk`，裸机 GCC 与 Picolibc 解包在 `toolchain/usr/`。若需按当前目录里的工具链重建 PK，可运行 `scripts/build-local-pk.sh`；脚本会配置 PK 并仅构建 `pk`。该本地构建路径使用 `riscv64-unknown-elf`，与上面的 GNU/Linux 工具链示例是两种可选配置。

---

## 阶段二：跑通第一个 RISC-V 程序

### 2.1 编写 C 语言测试程序
本项目已提供 `examples/hello.c`。也可以创建一个名为 `hello.c` 的文件：
```c
#include <stdio.h>

int main() {
    printf("Hello, RISC-V World running on Spike!\n");
    int a = 10;
    int b = 20;
    printf("10 + 20 = %d\n", a + b);
    return 0;
}
```

### 2.2 编译与运行
使用 RISC-V 交叉编译器将其编译为 ELF 文件，然后通过 Spike 运行。
```bash
# 编译
riscv64-linux-gnu-gcc -static examples/hello.c -o hello.elf

# 运行 (需要带上 pk 作为代理内核)
spike "$(find install -type f -name pk -print -quit)" hello.elf
```
**预期输出：** 屏幕将打印出 Hello 字符串和计算结果。

`-static` 会生成不依赖目标系统动态链接器的程序；PK 用于运行这种静态链接的 RISC-V ELF。请先确认 `find` 输出了 `pk` 的路径。

当前项目可直接运行 `scripts/run-local-hello.sh`。脚本用本地裸机 GCC、Picolibc 和 `examples/picolibc-pk-io.c` 编译同一份 `examples/hello.c`，再通过本地 Spike 与 PK 运行。`examples/picolibc-pk-start.S` 会在调用 `main` 前初始化 `gp`，否则 Picolibc 访问 `stdout` 时会发生访存异常。此路径已在当前 WSL2 环境验证，输出为上述 Hello 字符串和 `10 + 20 = 30`，退出码为 0。

若暂时只有裸机交叉编译器，可以先用项目中的 `examples/hello-syscall.c` 验证 PK 的 `write` 和 `exit` 系统调用。它不依赖目标 C 库：

```bash
riscv64-unknown-elf-gcc -nostdlib -static -mcmodel=medany \
    -Wl,-e,_start examples/hello-syscall.c -o examples/hello-syscall.elf
spike "$(find install -type f -name pk -print -quit)" examples/hello-syscall.elf
```

预期输出 `Hello from PK syscall!`，退出码为 0。本项目已在 Ubuntu 22.04 WSL2 上用 Spike `75fb7ef`、PK `9c61d29` 验证此路径；`printf` 示例需要目标 C 库，可使用 1.2 节的 GNU/Linux 工具链或上述 Picolibc 适配脚本。

### 2.3 裸机汇编验证 Spike

本项目提供 `examples/hello-bare.S`。它计算 `10 + 20`，通过 `tohost`/`fromhost` 与 Spike 通信，并以退出码 0 表示成功。普通裸机 ELF 若没有这两个符号，Spike 可能无法获知程序何时结束。

```bash
riscv64-linux-gnu-as -march=rv64gc -mabi=lp64d \
    -o examples/hello-bare.o examples/hello-bare.S
riscv64-linux-gnu-ld -Ttext-segment=0x80000000 \
    --section-start=.tohost=0x81000000 \
    -o examples/hello-bare.elf examples/hello-bare.o
spike -m64 examples/hello-bare.elf
echo $?  # 预期为 0
```

`-Ttext-segment=0x80000000` 让 ELF 的整个装载段落在 Spike 默认内存范围内。只设置 `-Ttext=0x80000000` 可能导致 ELF 装载段从 `0x7ffff000` 开始，出现 `Memory address 0x7ffff000 is invalid`。

---

## 阶段三：掌握交互式调试 (Interactive Debugging)

这是芯片工程师和底层软件工程师最常用的功能。

### 3.1 进入调试模式
使用 `-d` 参数启动 Spike：
```bash
spike -d "$(find install -type f -name pk -print -quit)" hello.elf
```
此时终端会暂停并显示 `(spike)` 提示符，等待你输入命令。

### 3.2 常用调试命令速查
在 `(spike)` 提示符下，你可以使用以下命令：

*   **执行控制：**
    *   `run` 或 `r`：全速运行，直到遇到断点或程序结束。
    *   `step [n]` 或 `s [n]`：单步执行 n 条指令（默认为 1）。
    *   `until pc 0 <address>`：一直执行，直到 Core 0 的 PC（程序计数器）到达指定地址。
    *   `quit` 或 `q`：退出调试器。
*   **状态查看：**
    *   `reg 0 a0`：查看 Core 0 的 `a0` 寄存器的值。
    *   `reg 0 pc`：查看当前 PC 的值。
    *   `freg 0 f0`：查看浮点寄存器的值。
    *   `mem <address>`：查看特定内存地址的数据。
    *   `dump`：打印所有寄存器的状态。

**实战练习：**
尝试在终端中先反汇编你的程序 (`riscv64-linux-gnu-objdump -d hello.elf > hello.asm`)，找到 `main` 函数的入口地址，然后在 Spike 调试器中使用 `until pc 0 <main_address>` 运行到 main 函数，接着用 `step` 单步执行，观察 `reg 0 a0` 等寄存器的变化。

---

## 阶段四：全系统启动与 OpenSBI

Spike 不仅能跑简单的 C 程序，还能模拟完整的操作系统启动流程。

### 4.1 理解 RISC-V 启动流程
在真实芯片或 Spike 中，启动 Linux 的标准流程是：
`Spike 硬件重置` -> `OpenSBI (M-Mode 固件)` -> `U-Boot (可选)` -> `Linux Kernel (S-Mode)` -> `RootFS (U-Mode)`

### 4.2 使用 Buildroot 快速体验
手动编译内核和文件系统较为繁琐，建议直接使用开源工具生成现成的镜像文件用于测试。您可以参考 [RISC-V Linux 官方指南](https://github.com/riscv/riscv-linux) 或者使用 Buildroot 为 Spike 构建一个精简的 Linux 镜像。

启动命令通常类似如下形式（需提供内核镜像文件、OpenSBI 固件以及文件系统）：
```bash
spike --isa=rv64gc -m2G \
      --kernel vmlinux \
      --initrd rootfs.cpio \
      opensbi/build/platform/generic/firmware/fw_payload.elf
```
*(注：进入此阶段意味着您开始接触 Linux 内核底层移植，需要具备较强的 Linux 知识背景。)*

---

## 阶段五：阅读源码与二次开发 (进阶)

当你需要添加自定义指令或修改硬件行为时，就需要修改 Spike 的源码了。

### 5.1 Spike 源码目录结构解析
*   `riscv/`：核心目录，包含指令解码 (`decode.h`)、寄存器状态 (`processor.h`) 和特权级处理。
*   `spike_main/`：入口函数 `main()` 所在，负责解析命令行参数并初始化模拟器。
*   `mmu/`：内存管理单元模拟。
*   `custom/`：自定义指令扩展（可在此处添加你的私有指令）。

### 5.2 尝试添加一条自定义指令 (思路导引)
1.  **定义指令编码**：在 `riscv/encoding.h` 中定义新指令的操作码（Opcode）、funct3 和 funct7。
2.  **编写执行逻辑**：在 `riscv/insns/` 目录下创建一个新的 C++ 文件（例如 `my_add.h`），在其中用 C++ 宏定义该指令执行时的硬件行为（如寄存器读写运算）。
3.  **注册指令**：修改 `riscv/riscv.mk.in`，将你的新指令源文件加入编译列表。
4.  **重新编译 Spike**。
5.  在 C 代码中使用 GCC 内联汇编（Inline Assembly）调用你的新指令，用重新编译过的 Spike 运行验证。

---
**参考资料与进阶阅读：**
* [RISC-V 官方特权级/非特权级指令集手册](https://riscv.org/technical/specifications/)
* [OpenSBI 官方仓库](https://github.com/riscv-software-src/opensbi)
