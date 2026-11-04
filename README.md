# Spike 学习环境

本仓库提供 Spike、Proxy Kernel（PK）的实践文档和可运行示例。详细安装与调试步骤见 [Spike 学习与实践指南](spike_risc_v_isa_simulator.md)。

`riscv-isa-sim/` 和 `riscv-pk/` 均指向 [JJFly-JOJO](https://github.com/JJFly-JOJO) 名下 fork 的 `develop` 分支，并固定在本仓库记录的提交。PK 的 `develop` 分支已包含 Ubuntu 22.04 binutils 所需的 CSR 兼容修改；`patches/` 中的补丁保留作上游差异参考。

首次获取源码时初始化两个子模块（Spike 还包含 SoftFloat 子模块）：

```bash
git clone --recurse-submodules https://github.com/JJFly-JOJO/spike.git
cd spike
git -C riscv-isa-sim switch develop
git -C riscv-pk switch develop
```

子模块初始化后默认停在固定提交；上面的 `switch` 命令将工作区切到各自 fork 的 `develop` 分支。修改子模块时，先在子模块内提交并推送 `develop`，随后在主仓库提交更新后的子模块引用。

构建依赖、交叉工具链和编译命令见指南的“阶段一”。完成安装后，可运行 `examples/hello-bare.S` 验证裸机执行，再运行 `examples/hello.c` 验证 PK 与 C 库。

`scripts/build-local-pk.sh` 和 `scripts/run-local-hello.sh` 用于当前项目目录内解包的 Ubuntu 裸机工具链与 Picolibc 环境；本地下载包、工具链和构建产物不会提交到 Git。
