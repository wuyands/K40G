#!/bin/bash
set -e

# ==========================================
# K40G (ares) 本地内核编译脚本
# 支持 ReSukiSU + SUSFS + KPM
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ===== 配置 =====
KERNEL_DIR="${KERNEL_DIR:-kernel}"
TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-clang}"
DEFCONFIG="${DEFCONFIG:-ares_defconfig}"
JOBS="${JOBS:-$(nproc)}"
KERNELSU_VARIANT="${KERNELSU_VARIANT:-resukisu}"
KERNELSU_BRANCH="${KERNELSU_BRANCH:-main}"
ENABLE_SUSFS="${ENABLE_SUSFS:-true}"
ENABLE_KPM="${ENABLE_KPM:-true}"
KERNEL_VERSION="${KERNEL_VERSION:-4.14}"

# ===== 颜色输出 =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ===== 函数 =====
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# ===== 1. 环境检查 =====
check_env() {
    info "检查编译环境..."
    
    # 检查必要工具
    local missing=()
    for cmd in git make clang curl zip; do
        if ! command -v $cmd &> /dev/null; then
            missing+=($cmd)
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        warn "缺少工具: ${missing[*]}"
        warn "请安装: sudo apt install git build-essential clang curl zip bc bison flex libssl-dev"
    fi
    
    # 检查 Proton Clang
    if [ ! -d "$TOOLCHAIN_DIR" ]; then
        info "下载 Proton Clang..."
        git clone --depth=1 https://github.com/kdrag0n/proton-clang -b master "$TOOLCHAIN_DIR"
    fi
    
    export PATH="$PWD/$TOOLCHAIN_DIR/bin:$PATH"
    success "Clang 版本: $(clang --version | head -n1)"
}

# ===== 2. 获取内核源码 =====
get_kernel() {
    info "获取内核源码..."
    
    if [ ! -d "$KERNEL_DIR" ]; then
        info "克隆小米内核源码 (ares-t-oss)..."
        git clone --depth=1 https://github.com/MiCode/Xiaomi_Kernel_OpenSource \
            -b ares-t-oss "$KERNEL_DIR"
    fi
    
    cd "$KERNEL_DIR"
    success "内核版本: $(make kernelversion)"
    cd "$SCRIPT_DIR"
}

# ===== 3. 应用设备补丁 =====
apply_device_patches() {
    info "应用设备补丁..."
    
    cd "$KERNEL_DIR"
    
    if [ -d "../ares/patches" ] && [ -n "$(ls -A ../ares/patches/*.patch 2>/dev/null)" ]; then
        for patch in ../ares/patches/*.patch; do
            info "应用补丁: $(basename $patch)"
            if git apply "$patch" 2>/dev/null; then
                success "  ✓ 成功"
            else
                warn "  ✗ 失败，跳过"
            fi
        done
    else
        warn "没有设备补丁"
    fi
    
    cd "$SCRIPT_DIR"
}

# ===== 4. 添加 KernelSU / ReSukiSU =====
add_kernelsu() {
    info "添加 $KERNELSU_VARIANT..."
    
    cd "$KERNEL_DIR"
    
    case "$KERNELSU_VARIANT" in
        resukisu)
            info "添加 ReSukiSU (分支: $KERNELSU_BRANCH)..."
            curl -LSs "https://raw.githubusercontent.com/ReSukiSU/kernel/main/setup.sh" | bash -s "$KERNELSU_BRANCH"
            ;;
        sukisu)
            info "添加 SukiSU-Ultra (susfs-dev)..."
            curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh" | bash -s susfs-dev
            ;;
        official)
            info "添加官方 KernelSU v0.9.5..."
            curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s v0.9.5
            ;;
        *)
            error "未知 KernelSU 变体: $KERNELSU_VARIANT"
            ;;
    esac
    
    success "$KERNELSU_VARIANT 添加完成"
    cd "$SCRIPT_DIR"
}

# ===== 5. 应用 SUSFS 补丁 =====
apply_susfs() {
    if [ "$ENABLE_SUSFS" != "true" ] || [ "$KERNELSU_VARIANT" = "sukisu" ]; then
        info "跳过 SUSFS 补丁"
        return
    fi
    
    info "应用 SUSFS 补丁 (内核版本: $KERNEL_VERSION)..."
    
    cd "$KERNEL_DIR"
    
    if [ -d "../patches/susfs/$KERNEL_VERSION" ] && [ -n "$(ls -A ../patches/susfs/$KERNEL_VERSION/*.patch 2>/dev/null)" ]; then
        for patch in ../patches/susfs/$KERNEL_VERSION/*.patch; do
            info "应用补丁: $(basename $patch)"
            if git apply "$patch" 2>/dev/null; then
                success "  ✓ 成功"
            else
                warn "  ✗ 失败，跳过"
            fi
        done
    else
        warn "未找到 SUSFS 补丁 (patches/susfs/$KERNEL_VERSION/)"
        warn "请将补丁文件放到对应目录"
    fi
    
    cd "$SCRIPT_DIR"
}

# ===== 6. 配置内核 =====
configure_kernel() {
    info "配置内核..."
    
    cd "$KERNEL_DIR"
    
    DEFCONFIG_PATH="arch/arm64/configs/$DEFCONFIG"
    
    if [ ! -f "$DEFCONFIG_PATH" ]; then
        error "Defconfig 不存在: $DEFCONFIG_PATH"
    fi
    
    # 追加 KSU + KPM 配置
    cat >> "$DEFCONFIG_PATH" << 'KSU_EOF'

# ==========================================
# ReSukiSU / KernelSU
# ==========================================
CONFIG_KSU=y
CONFIG_KSU_MTK_COMPAT=y

# ==========================================
# KPM (Kernel Patch Module)
# ==========================================
CONFIG_KPM=y
CONFIG_KSU_KPM=y
CONFIG_KSU_KPM_PARAMS=y
CONFIG_KALLSYMS=y
CONFIG_KALLSYMS_ALL=y
CONFIG_KALLSYMS_BASE_RELATIVE=y
CONFIG_MODULES=y
CONFIG_MODULE_UNLOAD=y
CONFIG_MODVERSIONS=y
CONFIG_MODULE_SRCVERSION_ALL=y
CONFIG_MODULE_FORCE_LOAD=y
CONFIG_MODULE_FORCE_UNLOAD=y

# ==========================================
# KPM Hook 基础设施
# ==========================================
CONFIG_KPROBES=y
CONFIG_HAVE_KPROBES=y
CONFIG_KPROBE_EVENTS=y
CONFIG_FUNCTION_TRACER=y
CONFIG_DYNAMIC_FTRACE=y
CONFIG_DYNAMIC_FTRACE_WITH_REGS=y
CONFIG_FTRACE_SYSCALLS=y
CONFIG_FUNCTION_GRAPH_TRACER=y
CONFIG_KPROBES_ON_FTRACE=y
CONFIG_UPROBES=y
KSU_EOF
    
    success "Defconfig 更新完成"
    
    # 生成配置
    export ARCH=arm64
    export SUBARCH=arm64
    export CC=clang
    export CROSS_COMPILE=aarch64-linux-gnu-
    export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
    
    make O=out "$DEFCONFIG"
    
    info "验证配置..."
    grep -E "CONFIG_(KSU|KPM|KALLSYMS_ALL|MODULES|KPROBES)=y" out/.config || true
    
    cd "$SCRIPT_DIR"
}

# ===== 7. 编译内核 =====
build_kernel() {
    info "开始编译 (使用 $JOBS 线程)..."
    
    cd "$KERNEL_DIR"
    
    export ARCH=arm64
    export SUBARCH=arm64
    export CC=clang
    export CROSS_COMPILE=aarch64-linux-gnu-
    export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
    export LD=ld.lld
    export AR=llvm-ar
    export NM=llvm-nm
    export OBJCOPY=llvm-objcopy
    export OBJDUMP=llvm-objdump
    export STRIP=llvm-strip
    
    if make O=out -j$JOBS 2>&1 | tee build.log; then
        success "编译成功！"
    else
        error "编译失败！查看 build.log 获取详情"
    fi
    
    info "输出文件:"
    ls -la out/arch/arm64/boot/
    
    cd "$SCRIPT_DIR"
}

# ===== 8. 打包 AnyKernel3 =====
package_anykernel() {
    info "打包 AnyKernel3..."
    
    if [ ! -d AnyKernel3 ]; then
        git clone --depth=1 https://github.com/osm0sis/AnyKernel3 AnyKernel3
    fi
    
    # 清理旧文件
    rm -f AnyKernel3/Image.gz AnyKernel3/Image.gz-dtb AnyKernel3/dtbo.img
    rm -rf AnyKernel3/dtb
    
    # 复制内核镜像
    if [ -f "$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb" ]; then
        cp "$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb" AnyKernel3/
        info "使用 Image.gz-dtb"
    elif [ -f "$KERNEL_DIR/out/arch/arm64/boot/Image.gz" ]; then
        cp "$KERNEL_DIR/out/arch/arm64/boot/Image.gz" AnyKernel3/
        info "使用 Image.gz"
    fi
    
    # MTK DTB
    if [ -d "$KERNEL_DIR/out/arch/arm64/boot/dts/mediatek" ]; then
        mkdir -p AnyKernel3/dtb
        cp "$KERNEL_DIR/out/arch/arm64/boot/dts/mediatek/"*.dtb AnyKernel3/dtb/
        info "复制 MTK DTB 文件"
    fi
    
    # DTBO
    if [ -f "$KERNEL_DIR/out/arch/arm64/boot/dtbo.img" ]; then
        cp "$KERNEL_DIR/out/arch/arm64/boot/dtbo.img" AnyKernel3/
        info "复制 dtbo.img"
    fi
    
    # 版本信息
    cat > AnyKernel3/version.txt << EOF
Device: Redmi K40 Gaming (ares)
Kernel: ares-t-oss (4.14.186)
KernelSU: $KERNELSU_VARIANT
SUSFS: $ENABLE_SUSFS
KPM: $ENABLE_KPM
Build Date: $(date +"%Y-%m-%d %H:%M")
Build by: Local Build
EOF
    
    # 设备信息
    sed -i 's/device.name1=.*/device.name1=ares/' AnyKernel3/anykernel.sh
    sed -i 's/device.name2=.*/device.name2=aresin/' AnyKernel3/anykernel.sh
    sed -i 's/device.name3=.*/device.name3=Redmi K40 Gaming/' AnyKernel3/anykernel.sh
    
    # 打包
    cd AnyKernel3
    ZIP_NAME="K40G-${KERNELSU_VARIANT}-$(date +%Y%m%d-%H%M).zip"
    zip -r9 "../$ZIP_NAME" * -x "*.git*" "README*"
    
    cd "$SCRIPT_DIR"
    success "刷机包已生成: $ZIP_NAME"
    ls -la "$ZIP_NAME"
}

# ===== 主菜单 =====
show_menu() {
    echo ""
    echo "=========================================="
    echo "  K40G 内核编译工具"
    echo "  设备: Redmi K40 Gaming (ares)"
    echo "  内核: 4.14.186"
    echo "=========================================="
    echo ""
    echo "  1. 完整编译（推荐）"
    echo "  2. 仅编译内核（跳过源码获取）"
    echo "  3. 重新配置并编译"
    echo "  4. 仅打包 AnyKernel3"
    echo "  5. 清理编译输出"
    echo "  0. 退出"
    echo ""
    echo -n "请选择: "
    read choice
    
    case $choice in
        1)
            check_env
            get_kernel
            apply_device_patches
            add_kernelsu
            apply_susfs
            configure_kernel
            build_kernel
            package_anykernel
            ;;
        2)
            check_env
            build_kernel
            package_anykernel
            ;;
        3)
            check_env
            configure_kernel
            build_kernel
            package_anykernel
            ;;
        4)
            package_anykernel
            ;;
        5)
            info "清理编译输出..."
            rm -rf "$KERNEL_DIR/out"
            rm -f K40G-*.zip
            success "清理完成"
            ;;
        0)
            info "退出"
            exit 0
            ;;
        *)
            error "无效选择"
            ;;
    esac
    
    echo ""
    success "全部完成！"
}

# 如果有参数，直接执行对应步骤
if [ $# -gt 0 ]; then
    case "$1" in
        all)
            check_env
            get_kernel
            apply_device_patches
            add_kernelsu
            apply_susfs
            configure_kernel
            build_kernel
            package_anykernel
            ;;
        build)
            check_env
            build_kernel
            ;;
        package)
            package_anykernel
            ;;
        clean)
            rm -rf "$KERNEL_DIR/out"
            rm -f K40G-*.zip
            ;;
        *)
            show_menu
            ;;
    esac
else
    show_menu
fi
