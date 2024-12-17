#!/bin/bash


# the following is a configuration, it only affects build/run, init does all

USE_RSS=0
USE_QEMU=0

while (( "$#" )); do
    case $1 in
        "--rss")
            USE_RSS=1
            ;;
        "--qemu")
            USE_QEMU=1
            ;;
    esac

    if [[ $1 == --* ]]; then
        shift 1
    else
        break
    fi
done

if [ "$USE_RSS" -ne 0 ] && [ "$USE_QEMU" -ne 0 ]; then
    echo "RSS and QEMU don't work together"
    exit 1
fi

# end of configuration


SCRIPTS="`dirname $0`"
ROOT="`realpath $SCRIPTS/..`"

SCRIPTS="$ROOT/scripts"
PROVIDED="$ROOT/provided"

EDK2="$ROOT/0.edk2"
TF_RMM="$ROOT/1.tf-rmm"
TF_RMM_QEMU="$ROOT/1.tf-rmm-qemu"
MBEDTLS="$ROOT/2.mbedtls"
TF_A="$ROOT/2.tf-a"
TF_A_RSS="$ROOT/2.tf-a-rss"
TF_A_QEMU="$ROOT/2.tf-a-qemu"
LINUX_CCA_HOST="$ROOT/3.linux-cca-host"
LINUX_CCA_REALM="$ROOT/4.linux-cca-realm"
DTC="$ROOT/5.dtc"
KVMTOOL="$ROOT/6.kvmtool"
KVM_UNIT_TESTS="$ROOT/7.kvm-unit-tests"

TOOLCHAINS="$ROOT/toolchains"
FVP="$ROOT/fvp"
QEMU="$ROOT/qemu"
OUT="$ROOT/out"
SHARED_DIR="$OUT/shared_dir"
INITRAMFS_HOST="$OUT/initramfs-host"
INITRAMFS_REALM="$OUT/initramfs-realm"


EDK2_MAIN_REMOTE=https://github.com/tianocore/edk2.git
EDK2_MAIN_REV=master
EDK2_PLATFORMS_REMOTE=https://github.com/tianocore/edk2-platforms
EDK2_PLATFORMS_REV=master
TF_RMM_REMOTE="https://github.com/Havner/trusted-firmware-rmm.git"
TF_RMM_REV=origin/eac5
TF_RMM_QEMU_REMOTE="https://git.codelinaro.org/linaro/dcap/rmm.git"
TF_RMM_QEMU_REV=origin/cca/v4
MBEDTLS_REMOTE="https://github.com/Mbed-TLS/mbedtls.git"
MBEDTLS_REV=mbedtls-3.4.1
TF_A_REMOTE="https://github.com/Havner/trusted-firmware-a.git"
TF_A_REV=origin/eac5
TF_A_RSS_REMOTE="https://github.com/Havner/trusted-firmware-a.git"
TF_A_RSS_REV=origin/eac5-rss
TF_A_QEMU_REMOTE="https://git.codelinaro.org/linaro/dcap/tf-a/trusted-firmware-a.git"
TF_A_QEMU_REV=origin/cca/v4
LINUX_CCA_HOST_REMOTE="https://git.gitlab.arm.com/linux-arm/linux-cca.git"
LINUX_CCA_HOST_REV=origin/cca-full/v5+v7
LINUX_CCA_REALM_REMOTE="https://git.gitlab.arm.com/linux-arm/linux-cca.git"
LINUX_CCA_REALM_REV=origin/cca-full/v5+v7
DTC_REMOTE="git://git.kernel.org/pub/scm/utils/dtc/dtc.git"
DTC_REV=origin/master
KVMTOOL_REMOTE="https://git.codelinaro.org/linaro/dcap/kvmtool.git"
KVMTOOL_REV=origin/cca/log
KVM_UNIT_TESTS_REMOTE="https://gitlab.arm.com/linux-arm/kvm-unit-tests-cca"
KVM_UNIT_TESTS_REV=origin/cca/rmm-v1.0-eac5

# https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
# for building tf-rmm and tf-a
GCC_AARCH64_NONE_ELF=https://developer.arm.com/-/media/Files/downloads/gnu/11.3.rel1/binrel/arm-gnu-toolchain-11.3.rel1-x86_64-aarch64-none-elf.tar.xz
GCC_ARM_NONE_EABI=https://developer.arm.com/-/media/Files/downloads/gnu/11.3.rel1/binrel/arm-gnu-toolchain-11.3.rel1-x86_64-arm-none-eabi.tar.xz
# for building linux kernel
GCC_AARCH64_NONE_LINUX=https://developer.arm.com/-/media/Files/downloads/gnu/11.3.rel1/binrel/arm-gnu-toolchain-11.3.rel1-x86_64-aarch64-none-linux-gnu.tar.xz
GCC_ARM_NONE_LINUX=https://developer.arm.com/-/media/Files/downloads/gnu/11.3.rel1/binrel/arm-gnu-toolchain-11.3.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz

function gcc_print_bin() {
    echo "$TOOLCHAINS/`basename "$1" | sed -s 's#\.tar\.xz##g'`/bin"
}

GCC_AARCH64_NONE_ELF_BIN=`gcc_print_bin "$GCC_AARCH64_NONE_ELF"`
GCC_ARM_NONE_EABI_BIN=`gcc_print_bin "$GCC_ARM_NONE_EABI"`
GCC_AARCH64_NONE_LINUX_BIN=`gcc_print_bin "$GCC_AARCH64_NONE_LINUX"`
GCC_ARM_NONE_LINUX_BIN=`gcc_print_bin "$GCC_ARM_NONE_LINUX"`

FVP_BASE_REVC=https://developer.arm.com/-/media/Files/downloads/ecosystem-models/FVP_Base_RevC-2xAEMvA_11.18_16_Linux64.tgz
FVP_SUBDIR=Base_RevC_AEMvA_pkg/models/Linux64_GCC-9.3

QEMU_REMOTE=https://git.codelinaro.org/linaro/dcap/qemu.git
QEMU_REV=origin/cca/v3
QEMU_BIN="$QEMU/build/qemu-system-aarch64"

FVP_BRANCH=fvp-cca


function save_path() {
    export OLDPATH=$PATH
}

function restore_path() {
    export PATH=$OLDPATH
    unset OLDPATH
}

function cleanup_json() {
    sed -i                          \
        -e '/"-m/d'                 \
        -e '/"-f/d'                 \
        -e '/"-W/d'                 \
        -e 's#".*gcc"#"gcc"#g'      \
        compile_commands.json
}

GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
RESET='\033[0m'

function color_blue() {
    echo -n -e "$BLUE"
}

function color_green() {
    echo -n -e "$GREEN"
}

function color_red() {
    echo -n -e "$RED"
}

function color_none() {
    echo -n -e "$RESET"
}

function start() {
    color_blue
    echo
    echo "=================================="
    echo "          $1"
    echo "=================================="
    color_none
}

function success() {
    color_green
    echo "$1 succeeded"
    color_none
}

function stop() {
    color_red
    echo "=================================="
    echo "   Last command failed, exiting"
    echo "=================================="
    color_none
    exit 1
}

function init_clean() {
    color_red
    echo "Starting from scratch..."
    color_none

    rm -rf "$EDK2"
    rm -rf "$TF_RMM"
    rm -rf "$TF_RMM_QEMU"
    rm -rf "$MBEDTLS"
    rm -rf "$TF_A"
    rm -rf "$TF_A_RSS"
    rm -rf "$TF_A_QEMU"
    rm -rf "$LINUX_CCA_HOST"
    rm -rf "$LINUX_CCA_REALM"
    rm -rf "$DTC"
    rm -rf "$KVMTOOL"
    rm -rf "$KVM_UNIT_TESTS"
    rm -rf "$TOOLCHAINS"
    rm -rf "$FVP"
    rm -rf "$QEMU"
    rm -rf "$OUT"
}

function init_edk2() {
    start ${FUNCNAME[0]}
    mkdir -p "$EDK2"
    pushd "$EDK2"
    git clone --recursive "$EDK2_MAIN_REMOTE"                           || stop
    pushd edk2
    git checkout --recurse-submodules -t -b fvp-cca $EDK2_MAIN_REV      || stop
    touch .projectile
    popd
    git clone --recursive "$EDK2_PLATFORMS_REMOTE"                      || stop
    pushd edk2-platforms
    git checkout --recurse-submodules -t -b fvp-cca $EDK2_PLATFORMS_REV || stop
    touch .projectile
    popd
    popd
    success ${FUNCNAME[0]}
}

function init_tf_rmm() {
    start ${FUNCNAME[0]}
    git clone --recursive "$TF_RMM_REMOTE" "$TF_RMM"                    || stop
    pushd "$TF_RMM"
    git checkout --recurse-submodules -t -b $FVP_BRANCH $TF_RMM_REV     || stop
    touch .projectile
    popd
    git clone --recursive "$TF_RMM_QEMU_REMOTE" "$TF_RMM_QEMU"          || stop
    pushd "$TF_RMM_QEMU"
    # for some reason --recurse-submodules doesn't work here
    git checkout -t -b $FVP_BRANCH $TF_RMM_QEMU_REV                     || stop
    git submodule update --init --recursive                             || stop
    touch .projectile
    popd
    success ${FUNCNAME[0]}
}

function init_tf_a() {
    start ${FUNCNAME[0]}
    git clone "$MBEDTLS_REMOTE" "$MBEDTLS"                              || stop
    pushd "$MBEDTLS"
    git checkout -b $FVP_BRANCH $MBEDTLS_REV                            || stop
    touch .projectile
    popd
    git clone "$TF_A_REMOTE" "$TF_A"                                    || stop
    pushd "$TF_A"
    git checkout -t -b $FVP_BRANCH $TF_A_REV                            || stop
    touch .projectile
    popd
    git clone "$TF_A_RSS_REMOTE" "$TF_A_RSS"                            || stop
    pushd "$TF_A_RSS"
    git checkout -t -b $FVP_BRANCH $TF_A_RSS_REV                        || stop
    touch .projectile
    popd
    git clone "$TF_A_QEMU_REMOTE" "$TF_A_QEMU"                          || stop
    pushd "$TF_A_QEMU"
    git checkout -t -b $FVP_BRANCH $TF_A_QEMU_REV                       || stop
    touch .projectile
    popd
    success ${FUNCNAME[0]}
}

function init_linux_host() {
    start ${FUNCNAME[0]}
    git clone "$LINUX_CCA_HOST_REMOTE" "$LINUX_CCA_HOST"                || stop
    pushd "$LINUX_CCA_HOST"
    git checkout -t -b $FVP_BRANCH $LINUX_CCA_HOST_REV                  || stop
    touch .projectile
    cp -v "$PROVIDED/config-linux-host" "$LINUX_CCA_HOST/.config"       || stop
    popd
    success ${FUNCNAME[0]}
}

function init_linux_realm() {
    start ${FUNCNAME[0]}
    git clone "$LINUX_CCA_REALM_REMOTE" "$LINUX_CCA_REALM"              || stop
    pushd "$LINUX_CCA_REALM"
    git checkout -t -b $FVP_BRANCH $LINUX_CCA_REALM_REV                 || stop
    touch .projectile
    cp -v "$PROVIDED/config-linux-realm" "$LINUX_CCA_REALM/.config"     || stop
    popd
    success ${FUNCNAME[0]}
}

function init_dtc() {
    start ${FUNCNAME[0]}
    git clone "$DTC_REMOTE" "$DTC"                                      || stop
    pushd "$DTC"
    git checkout -t -b $FVP_BRANCH $DTC_REV                             || stop
    touch .projectile
    popd
    success ${FUNCNAME[0]}
}

function init_kvmtool() {
    start ${FUNCNAME[0]}
    git clone "$KVMTOOL_REMOTE" "$KVMTOOL"                              || stop
    pushd "$KVMTOOL"
    git checkout -t -b $FVP_BRANCH $KVMTOOL_REV                         || stop
    touch .projectile
    popd
    success ${FUNCNAME[0]}
}

function init_kvm_unit_tests() {
    start ${FUNCNAME[0]}
    git clone "$KVM_UNIT_TESTS_REMOTE" "$KVM_UNIT_TESTS"                || stop
    pushd "$KVM_UNIT_TESTS"
    git checkout -t -b $FVP_BRANCH $KVM_UNIT_TESTS_REV                  || stop
    git submodule update --init                                         || stop
    touch .projectile
    ./configure                                                         \
        --arch=arm64                                                    \
        --cross-prefix=aarch64-linux-gnu-                               \
        --target=kvmtool                                                || stop
    popd
    success ${FUNCNAME[0]}
}

function init_toolchains() {
    start ${FUNCNAME[0]}
    mkdir "$TOOLCHAINS"                                                 || stop
    pushd "$TOOLCHAINS"
    for LINK in "$GCC_AARCH64_NONE_ELF" "$GCC_ARM_NONE_EABI" "$GCC_AARCH64_NONE_LINUX" "$GCC_ARM_NONE_LINUX"; do
        wget "$LINK"                                                    || stop
        FILELINK="`basename "$LINK"`"
        echo "Unpacking $FILELINK"
        tar xf "$FILELINK"                                              || stop
        unset FILELINK
    done
    popd
    success ${FUNCNAME[0]}
}

function init_fvp() {
    start ${FUNCNAME[0]}
    mkdir "$FVP"                                                        || stop
    pushd "$FVP"
    wget "$FVP_BASE_REVC"                                               || stop
    FILELINK="`basename "$FVP_BASE_REVC"`"
    echo "Unpacking $FILELINK"
    tar xf "$FILELINK"                                                  || stop
    unset FILELINK
    popd
    success ${FUNCNAME[0]}
}

function init_qemu() {
    start ${FUNCNAME[0]}
    git clone "$QEMU_REMOTE" "$QEMU"                                    || stop
    pushd "$QEMU"
    git checkout --recurse-submodules -t -b $FVP_BRANCH $QEMU_REV       || stop
    ./configure --target-list=aarch64-softmmu                           || stop
    touch .projectile
    popd
    success ${FUNCNAME[0]}
}

function init_out() {
    start ${FUNCNAME[0]}
    mkdir "$OUT"                                                        || stop
    mkdir "$INITRAMFS_HOST"                                             || stop
    mkdir "$INITRAMFS_REALM"                                            || stop
    mkdir "$SHARED_DIR"                                                 || stop
    cp -v "$PROVIDED/config-fvp" "$OUT"                                 || stop
    cp -v "$PROVIDED/grub.cfg" "$OUT"                                   || stop
    cp -v "$PROVIDED/bootaa64.efi" "$OUT"                               || stop
    cp -v "$PROVIDED/realm.sh" "$SHARED_DIR"                            || stop
    cp -v "$PROVIDED/hexdump.sh" "$SHARED_DIR"                          || stop
    cp -v "$PROVIDED/module.sh" "$SHARED_DIR"                           || stop
    echo "Unpacking $PROVIDED/initramfs-host.tar.bz2 -> $INITRAMFS_HOST"
    tar xf "$PROVIDED/initramfs-host.tar.bz2" -C "$INITRAMFS_HOST"      || stop
    echo "Unpacking $PROVIDED/initramfs-realm.tar.bz2 -> $INITRAMFS_REALM"
    tar xf "$PROVIDED/initramfs-realm.tar.bz2" -C "$INITRAMFS_REALM"    || stop
    success ${FUNCNAME[0]}
}

function init() {
    color_green
    echo "If the command fails with some directory \"already exists and is not an empty directory\""
    echo "It means you already did an init or at least started it. Do init_clean before init."
    color_none

    init_edk2
    init_tf_rmm
    init_tf_a
    init_linux_host
    init_linux_realm
    init_dtc
    init_kvmtool
    init_kvm_unit_tests
    init_toolchains
    init_fvp
    init_qemu
    init_out
}

function build_edk2() {
    start ${FUNCNAME[0]}

    if [ "$USE_QEMU" -ne 0 ]; then
        EDK2_PLATFORM=ArmVirtPkg/ArmVirtQemuKernel.dsc
        EDK2_BIN=Build/ArmVirtQemuKernel-AARCH64/RELEASE_GCC5/FV/QEMU_EFI.fd
    else
        EDK2_PLATFORM=Platform/ARM/VExpressPkg/ArmVExpress-FVP-AArch64.dsc
        EDK2_BIN=Build/ArmVExpress-FVP-AArch64/RELEASE_GCC5/FV/FVP_AARCH64_EFI.fd
    fi

    pushd "$EDK2"
    export WORKSPACE="$EDK2"
    export PACKAGES_PATH="$EDK2/edk2:$EDK2/edk2-platforms"
    source edk2/edksetup.sh
    make -C edk2/BaseTools                                              || stop
    export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
    bash build -b RELEASE -a AARCH64 -t GCC5 -p $EDK2_PLATFORM          || stop
    cp -v "$EDK2_BIN" "$OUT"                                            || stop
    unset GCC5_AARCH64_PREFIX
    unset WORKSPACE
    unset PACKAGES_PATH
    unset EDK_TOOLS_PATH
    unset CONF_PATH
    popd
    success ${FUNCNAME[0]}
}

function build_tf_rmm() {
    start ${FUNCNAME[0]}

    if [ "$USE_QEMU" -ne 0 ]; then
        TF_RMM_DIR="$TF_RMM_QEMU"
        TF_RMM_CONFIG=qemu_virt_defcfg
    else
        TF_RMM_DIR="$TF_RMM"
        TF_RMM_CONFIG=fvp_defcfg
    fi

    save_path
    export PATH="$GCC_AARCH64_NONE_ELF_BIN:$PATH"
    export CROSS_COMPILE=aarch64-none-elf-
    pushd "$TF_RMM_DIR"
    cmake                                                               \
        -DRMM_CONFIG=$TF_RMM_CONFIG                                     \
        -DRMM_PRINT_RIM=1                                               \
        -DLOG_LEVEL=40                                                  \
        -S . -B build/                                                  || stop
    bear --append -- cmake --build build/                               || stop
    cleanup_json
    cp -fv "$TF_RMM_DIR/build/Release/rmm.img" "$OUT"                   || stop
    popd
    unset CROSS_COMPILE
    restore_path
    success ${FUNCNAME[0]}
}


# The ENABLE_*=0 lines are so BL31 can fit into the memory.
# Refer to 2.tf-a/plat/arm/board/fvp/platform.mk:27
# The disabled are chosen arbitrarily by trial and error so
# BL31 fits into the memory and still somehow works (hopefully).
TF_A_OPTS="PLAT=fvp                                            \
           MEASURED_BOOT=1                                     \
           FVP_HW_CONFIG_DTS=fdts/fvp-base-gicv3-psci-1t.dts   \
           BL33=$OUT/FVP_AARCH64_EFI.fd"

TF_A_OPTS_RSS="$TF_A_OPTS                        \
               PLAT_RSS_COMMS_USE_SERIAL=1       \
               ENABLE_FEAT_AMUv1p1=0             \
               ENABLE_MPAM_FOR_LOWER_ELS=0       \
               ENABLE_FEAT_GCS=0                 \
               ENABLE_FEAT_RAS=0                 \
               ENABLE_TRBE_FOR_NS=0              \
               ENABLE_SYS_REG_TRACE_FOR_NS=0     \
               ENABLE_TRF_FOR_NS=0               \
               ENABLE_FEAT_S2PIE=0               \
               ENABLE_FEAT_S1PIE=0               \
               ENABLE_FEAT_S2POE=0               \
               ENABLE_FEAT_S1POE=0"

TF_A_OPTS_QEMU="PLAT=qemu                                           \
                QEMU_USE_GIC_DRIVER=QEMU_GICV3                      \
                BL33=$OUT/QEMU_EFI.fd"

function build_tf_a() {
    start ${FUNCNAME[0]}

    if [ "$USE_RSS" -ne 0 ]; then
        TF_A_DIR="$TF_A_RSS"
        TF_A_CONFIG="$TF_A_OPTS_RSS"
    elif [ "$USE_QEMU" -ne 0 ]; then
        TF_A_DIR="$TF_A_QEMU"
        TF_A_CONFIG="$TF_A_OPTS_QEMU"
    else
        TF_A_DIR="$TF_A"
        TF_A_CONFIG="$TF_A_OPTS"
    fi

    save_path
    export PATH="$GCC_AARCH64_NONE_ELF_BIN:$PATH"
    pushd "$TF_A_DIR"
    bear --append -- make CROSS_COMPILE=aarch64-none-elf-               \
         ENABLE_RME=1                                                   \
         MBEDTLS_DIR=../2.mbedtls                                       \
         RMM="$OUT/rmm.img"                                             \
         $TF_A_CONFIG                                                   \
         all fip                                                        || stop
    cleanup_json
    if [ "$USE_QEMU" -ne 0 ]; then
        dd if="$TF_A_DIR/build/qemu/release/bl1.bin" of="$TF_A_DIR/flash.bin"                 || stop
        dd if="$TF_A_DIR/build/qemu/release/fip.bin" of="$TF_A_DIR/flash.bin" seek=64 bs=4096 || stop
        cp -fv "$TF_A_DIR/flash.bin" "$OUT"                                                   || stop
    else
        cp -fv "$TF_A_DIR/build/fvp/release/bl1.bin" "$OUT"             || stop
        cp -fv "$TF_A_DIR/build/fvp/release/fip.bin" "$OUT"             || stop
    fi
    popd
    restore_path
    success ${FUNCNAME[0]}
}

function build_linux_host() {
    start ${FUNCNAME[0]}
    save_path
    export PATH="$GCC_AARCH64_NONE_LINUX_BIN:$PATH"
    pushd "$LINUX_CCA_HOST"
    bear --append -- make LOCALVERSION=""                               \
         CROSS_COMPILE="/usr/bin/ccache aarch64-none-linux-gnu-"        \
         ARCH=arm64                                                     \
         -j8                                                            || stop
    cleanup_json
    cp -fv "$LINUX_CCA_HOST/arch/arm64/boot/Image" "$OUT"               || stop
    cp -fv "$LINUX_CCA_HOST/arch/arm64/boot/dts/arm/fvp-base-revc.dtb" "$OUT" || stop
    popd
    restore_path
    success ${FUNCNAME[0]}
}

function build_linux_realm() {
    start ${FUNCNAME[0]}
    save_path
    export PATH="$GCC_AARCH64_NONE_LINUX_BIN:$PATH"
    pushd "$LINUX_CCA_REALM"
    bear --append -- make LOCALVERSION=""                               \
         CROSS_COMPILE="/usr/bin/ccache aarch64-none-linux-gnu-"        \
         ARCH=arm64                                                     \
         -j8                                                            || stop
    cleanup_json
    cp -fv "$LINUX_CCA_REALM/arch/arm64/boot/Image" "$SHARED_DIR/Image.realm" || stop
    popd
    restore_path
    success ${FUNCNAME[0]}
}

function build_libfdt() {
    start ${FUNCNAME[0]}
    pushd "$DTC"
    # this is built using cross compiler (gcc9) from ubuntu
    bear --append -- make CC=aarch64-linux-gnu-gcc libfdt               || stop
    cleanup_json
    popd
    success ${FUNCNAME[0]}
}

function build_kvmtool() {
    start ${FUNCNAME[0]}
    pushd "$KVMTOOL"
    # this is built using cross compiler (gcc9) from ubuntu, it crashes on gcc11 from arm
    bear --append -- make CROSS_COMPILE=aarch64-linux-gnu-              \
         LDFLAGS=-static                                                \
         ARCH=arm64                                                     \
         LIBFDT_DIR="$DTC/libfdt"                                       || stop
    cleanup_json
    cp -fv "$KVMTOOL/lkvm" "$SHARED_DIR"                                || stop
    popd
    success ${FUNCNAME[0]}
}

function build_kvm_unit_tests() {
    start ${FUNCNAME[0]}
    pushd "$KVM_UNIT_TESTS"
    # this is built using cross compiler (gcc9) from ubuntu
    bear --append -- make                                               || stop
    cleanup_json
    KVM_TESTS="$SHARED_DIR/kvm-tests"
    rm -rf "$KVM_TESTS"                                                 || stop
    mkdir "$KVM_TESTS"                                                  || stop
    cp arm/*.flat arm/run-realm-tests "$KVM_TESTS"                      || stop
    sed -i -e "s#-lkvm#-/shared/lkvm#g#" "$KVM_TESTS/run-realm-tests"   || stop
    unset KVM_TESTS
    popd
    success ${FUNCNAME[0]}
}

function build_root_host() {
    start ${FUNCNAME[0]}
    pushd "$INITRAMFS_HOST"
    find . -print0 |                                                    \
        cpio --null --create --verbose --format=newc |                  \
        gzip --best > "$OUT/initramfs-host.cpio.gz"                     || stop
    BOOT_IMG="$OUT/boot.img"
    rm -f "$BOOT_IMG"                                                   || stop
    mformat -i "$BOOT_IMG" -n 64 -h 2 -T 1048576 -v "BOOT IMG" -C ::    || stop
    mcopy -i "$BOOT_IMG" "$OUT/Image" ::                                || stop
    mcopy -i "$BOOT_IMG" "$OUT/fvp-base-revc.dtb" ::                    || stop
    mmd -i "$BOOT_IMG" ::/EFI                                           || stop
    mmd -i "$BOOT_IMG" ::/EFI/BOOT                                      || stop
    mcopy -i "$BOOT_IMG" "$OUT/initramfs-host.cpio.gz" ::               || stop
    mcopy -i "$BOOT_IMG" "$OUT/bootaa64.efi" ::/EFI/BOOT                || stop
    mcopy -i "$BOOT_IMG" "$OUT/grub.cfg" ::/EFI/BOOT                    || stop
    popd
    success ${FUNCNAME[0]}
}

function build_root_realm() {
    start ${FUNCNAME[0]}
    pushd "$INITRAMFS_REALM"
    find . -print0 |                                                    \
        cpio --null --create --verbose --format=newc |                  \
        gzip --best > "$SHARED_DIR/initramfs-realm.cpio.gz"             || stop
    popd
    success ${FUNCNAME[0]}
}

function build_qemu() {
    start ${FUNCNAME[0]}
    pushd "$QEMU"
    bear --append -- make -j8                                           || stop
    cleanup_json
    popd
    success ${FUNCNAME[0]}
}

function build() {
    if [ ! -d "$OUT" ]; then
        color_red
        echo "You need to initialize first, run with 'init'."
        color_none
        exit 1
    fi

    build_edk2
    build_tf_rmm
    build_tf_a
    build_linux_host
    build_linux_realm
    build_libfdt
    build_kvmtool
    build_kvm_unit_tests
    build_root_host
    build_root_realm
    if [ "$USE_QEMU" -ne 0 ]; then
        build_qemu
    fi
}

function run() {
    if [ "$USE_QEMU" -ne 0 ]; then
        run_qemu
    else
        run_fvp
    fi
}

function run_fvp() {
    start ${FUNCNAME[0]}
    pushd "$FVP/$FVP_SUBDIR"
    ./FVP_Base_RevC-2xAEMvA                                             \
        -f "$OUT/config-fvp"                                            \
        -Q 1000                                                         \
        -C bp.secureflashloader.fname="$OUT/bl1.bin"                    \
        -C bp.flashloader0.fname="$OUT/fip.bin"                         \
        -C bp.virtioblockdevice.image_path="$OUT/boot.img"              \
        -C bp.virtiop9device.root_path="$SHARED_DIR"                    || stop
    popd
}

function run_qemu() {
    start ${FUNCNAME[0]}
    $QEMU_BIN                                                           \
        -M virt,virtualization=on,secure=on,gic-version=3               \
        -M acpi=off -cpu max,x-rme=on -m 8G -smp 8                      \
        -nographic                                                      \
        -bios "$OUT/flash.bin"                                          \
        -kernel "$OUT/Image"                                            \
        -initrd "$OUT/initramfs-host.cpio.gz"                           \
        -device virtio-net-pci,netdev=net0                              \
        -netdev tap,id=net0,ifname=cca0,script=no                       \
        -device virtio-9p-device,fsdev=shr0,mount_tag=FM                \
        -fsdev local,security_model=none,path="$SHARED_DIR",id=shr0
}

function net_start() {
    ip a show cca0 > /dev/null 2>&1
    if [ "$?" == 0 ]; then
        echo "Network already started"
        exit 1
    fi

    sudo ip tuntap add dev cca0 mode tap user $USER
    sudo ip link set dev cca0 up
    sudo ip addr add 192.168.30.1/24 dev cca0

    echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
    sudo iptables -t nat -A POSTROUTING -j MASQUERADE -s 192.168.30.0/24
}

function net_stop() {
    ip a show cca0 > /dev/null 2>&1
    if [ "$?" == 1 ]; then
        echo "Network already stopped"
        exit 1
    fi

    sudo iptables -t nat -D POSTROUTING -j MASQUERADE -s 192.168.30.0/24
    echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward

    sudo ip addr del 192.168.30.1/24 dev cca0
    sudo ip link set dev cca0 down
    sudo ip tuntap del dev cca0 mode tap
}

function usage() {
    echo "Run with a target function name for what you intend to do.

Possible targets are:
  init_clean
  init_edk2
  init_tf_rmm
  init_tf_a
  init_linux_host
  init_linux_realm
  init_dtc
  init_kvmtool
  init_kvm_unit_tests
  init_toolchains
  init_fvp
  init_qemu
  init_out
  init           (does all the inits above excluding clean)
  build_edk2
  build_tf_rmm
  build_tf_a
  build_linux_host
  build_linux_realm
  build_libfdt
  build_kvmtool
  build_kvm_unit_tests
  build_root_host
  build_root_realm
  build_qemu
  build          (does all the builds above in the correct order)
  run

  net_start      (requires root/sudo, allows to connect to FVP/realm)
  net_stop       (requires root/sudo, cleans up after net_start)

Running without argument does:
  build
  run

Initialization should be performed just once."
}

if [ "$1" == "-h" -o "$1" == "--help" ]; then
    usage
    exit 0
fi

if [ "$#" == 0 ]; then
    build
    run
else
    while (( "$#" )); do
        echo $1
        if [[ "$1" = "init"* ]] || [[ "$1" = "build"* ]] || [[ "$1" = "net"* ]] || [ "$1" == "run" ]; then
            eval "$1"
        elif [ "$1" ]; then
            echo "Wrong argument passed."
            echo "Run with -h or --help to see usage."
            exit 1
        fi
        shift
    done
fi

# Local Variables:
# indent-tabs-mode: nil
# End:
