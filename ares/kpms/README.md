# KPM 模块目录

将需要嵌入内核的 .kpm (Kernel Patch Module) 文件放在这里。

## KPM 模块说明

KPM（Kernel Patch Module）是运行在内核空间的模块，类似于 LKM（可加载内核模块），但支持：
- 内核函数 inline hook
- 系统调用表 hook
- 动态内核补丁

## 使用方式

### 1. Embed（嵌入）- 编译时内置
在 GitHub Actions 运行时，在 `EMBED_KPMS` 参数中填入模块名（逗号分隔）：
```
module1,module2,module3
```

对应的 .kpm 文件需要放在此目录下：
```
ares/kpms/module1.kpm
ares/kpms/module2.kpm
```

### 2. Load（加载）- 运行时动态加载
通过 ReSukiSU 管理器或命令行加载：
```bash
kpm load your-module.kpm
```

### 3. Install（安装）- 持久化安装
安装到 /data 分区，开机自动加载：
```bash
kpm install your-module.kpm
```

## 常用 KPM 模块

| 模块 | 功能 | 推荐 |
|------|------|------|
| susfs.kpm | SUSFS 隐藏增强 | ✅ |
| bootlog.kpm | 开机日志捕获 | 可选 |
| perf.kpm | 性能调度优化 | 可选 |
| fps.kpm | 帧率解锁/限制 | 可选 |

## 注意事项
1. KPM 模块必须与内核版本（4.14.186）严格匹配编译
2. 嵌入的 KPM 会在开机早期阶段加载
3. 动态加载的 KPM 重启后失效
