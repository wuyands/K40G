# K40G Kernel Build

Redmi K40 Gaming (ares) 内核构建项目，支持 **ReSukiSU + SUSFS + KPM** 三件套。

## 设备信息

| 项目 | 内容 |
|------|------|
| 设备 | Redmi K40 Gaming / POCO F3 GT |
| 代号 | ares (国行) / aresin (印度版) |
| 处理器 | MediaTek MT6893 / Dimensity 1200 |
| 内核版本 | 4.14.186 |
| 安卓版本 | Android 13 (MIUI 14 / HyperOS) |
| 架构 | arm64 |

## 功能特性

- ✅ **ReSukiSU** - 基于 KernelSU，专注 Non-GKI 稳定性
- ✅ **SUSFS** - 隐藏 Root 痕迹，绕过检测
- ✅ **KPM** - Kernel Patch Module 支持，可加载 .kpm 模块
- ✅ **MTK 平台兼容** - 针对天玑处理器优化
- ✅ **GitHub Actions** - 云端自动编译
- ✅ **本地编译** - 支持本地一键编译脚本
- ✅ **AnyKernel3** - 标准刷机包格式

## 快速开始

### 方式一：GitHub Actions 云端编译（推荐）

1. Fork 本仓库到你的 GitHub 账号
2. 进入仓库的 **Actions** 标签页
3. 选择 **Build Kernel for Redmi K40 Gaming (ares) - A13**
4. 点击 **Run workflow**，根据需要调整参数
5. 等待编译完成，从 Artifacts 下载刷机包

#### 可配置参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| KERNEL_SOURCE | MiCode 开源内核 | 内核源码地址 |
| KERNEL_BRANCH | ares-t-oss | 内核分支 |
| DEFCONFIG | ares_defconfig | 内核配置文件 |
| KERNELSU_VARIANT | resukisu | Root 方案 (resukisu/sukisu/official) |
| KERNELSU_BRANCH | main | KernelSU 分支 |
| ENABLE_SUSFS | true | 是否启用 SUSFS |
| ENABLE_KPM | true | 是否启用 KPM 支持 |
| EMBED_KPMS | (空) | 嵌入的 KPM 模块，逗号分隔 |
| CLANG_VERSION | proton-master | Clang 版本 |
| KERNEL_VERSION | 4.14 | 内核大版本（用于 SUSFS 补丁） |

### 方式二：本地编译

```bash
# 克隆仓库
git clone https://github.com/wuyands/K40G.git
cd K40G

# 一键完整编译
chmod +x build.sh
./build.sh all

# 或使用交互式菜单
./build.sh
```

编译完成后，刷机包位于项目根目录，命名格式为：
```
K40G-resukisu-YYYYMMDD-HHMM.zip
```

## 目录结构

```
K40G/
├── .github/
│   └── workflows/
│       └── build-ares-a13.yml    # GitHub Actions 工作流
├── ares/
│   ├── config                     # 设备配置文件
│   ├── patches/                   # 设备专用补丁
│   │   └── README.md
│   └── kpms/                      # KPM 模块（用于嵌入）
│       └── README.md
├── patches/
│   └── susfs/
│       ├── README.md
│       └── 4.14/                  # 4.14 内核 SUSFS 补丁
├── tools/                         # 辅助工具
├── docs/                          # 文档
├── build.sh                       # 本地编译脚本
└── README.md                      # 本文件
```

## KPM 使用说明

### 什么是 KPM？

KPM（Kernel Patch Module）是运行在内核空间的模块，类似于 LKM，但支持：
- 内核函数 **inline hook**
- 系统调用表 **hook**
- 动态内核补丁

### 三种使用方式

#### 1. Embed（嵌入）- 编译时内置
在 GitHub Actions 的 `EMBED_KPMS` 参数中填入模块名：
```
module1,module2
```

将 `.kpm` 文件放到 `ares/kpms/` 目录下。

#### 2. Load（加载）- 运行时动态加载
```bash
kpm load your-module.kpm
```

#### 3. Install（安装）- 持久化安装
```bash
kpm install your-module.kpm
```

## 测试建议

按以下顺序逐步测试，降低变砖风险：

```
第1步：纯内核编译（无 Root）
  ↓ 确认能正常开机
第2步：仅 ReSukiSU（无 SUSFS，无 KPM）
  ↓ 确认 Root 正常
第3步：开启 KPM 支持
  ↓ 确认能加载 .kpm 模块
第4步：添加 SUSFS
  ↓ 确认隐藏效果
第5步：嵌入常用 KPM 模块
  ↓ 最终版本
```

## 常见问题

### Q: 编译成功但刷入卡米？
A: 可能是 kprobe 不稳定。尝试：
1. 改用 SukiSU magic 分支
2. 检查 defconfig 中的 MTK 兼容配置
3. 关闭某些调试选项

### Q: WiFi 失效？
A: 确认内核分支与系统版本匹配。`ares-t-oss` 对应 Android 13。

### Q: KPM 模块加载失败？
A: 检查：
1. `CONFIG_KALLSYMS_ALL=y` 是否开启
2. KPM 模块是否与当前内核版本匹配编译
3. 查看 dmesg 日志中的错误信息

### Q: SUSFS 补丁应用失败？
A: 4.14 子版本较多，可能需要调整补丁偏移。尝试：
1. 使用其他版本的 SUSFS 补丁
2. 手动调整 patch 的偏移量
3. 使用 SukiSU 内置的 SUSFS

## 注意事项

1. **刷机有风险**，请确保已备份重要数据
2. 建议先在第三方 Recovery（如 TWRP）中测试
3. MTK 平台的 Bootloader 解锁可能需要官方工具
4. KPM 模块需要与内核版本严格匹配
5. 本项目仅供学习交流使用

## 相关链接

- [ReSukiSU 官网](https://resukisu.github.io/)
- [SukiSU-Ultra 官网](https://sukisu.org/)
- [KernelSU 官网](https://kernelsu.org/)
- [小米内核开源](https://github.com/MiCode/Xiaomi_Kernel_OpenSource)
- [AnyKernel3](https://github.com/osm0sis/AnyKernel3)
- [APatch KPM 文档](https://apatch.dev/kpm-usage-guide.html)

## License

GPL-2.0
