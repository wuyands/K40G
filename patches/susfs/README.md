# SUSFS 补丁目录

按内核版本分类存放 SUSFS 补丁。

## 目录结构
```
patches/susfs/
├── 4.14/          # 4.14 内核专用补丁
├── 4.19/          # 4.19 内核专用补丁
├── 5.4/           # 5.4 内核专用补丁
└── 5.10/          # 5.10 内核专用补丁
```

## 4.14 内核补丁说明

对于 K40G (ares) 的 4.14.186 内核，请将对应的 SUSFS 补丁放在 `4.14/` 目录下。

### 补丁获取方式

1. **从 SukiSU-Ultra 获取**
   ```bash
   git clone https://github.com/SukiSU-Ultra/SukiSU-Ultra
   # 补丁位于 SukiSU/kernel/susfs/patches/4.14/
   ```

2. **从 KernelSU-Next 获取**
   ```bash
   git clone https://github.com/KernelSU-Next/kernel
   # 补丁位于 kernel/susfs/patches/
   ```

3. **从 George-Seven/SUSFS 获取**
   ```bash
   git clone https://github.com/George-Seven/SUSFS
   # 补丁位于 patches/4.14/
   ```

## 注意事项

1. 确保补丁版本与内核子版本匹配（4.14.186）
2. 补丁应用失败不影响编译，但 SUSFS 功能可能不完整
3. 如遇到冲突，可尝试调整补丁偏移或使用其他版本补丁
