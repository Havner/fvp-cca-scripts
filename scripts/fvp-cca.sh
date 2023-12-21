#!/bin/bash

#set -x

SCRIPTS="`dirname $0`"
ROOT="`realpath $SCRIPTS/..`"

SCRIPTS="$ROOT/scripts"
PROVIDED="$ROOT/provided"

EDK2="$ROOT/0.edk2"
TF_RMM="$ROOT/1.tf-rmm"
MBEDTLS="$ROOT/2.mbedtls"
TF_A="$ROOT/2.tf-a"
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

EDK2_REMOTE=https://github.com/tianocore/edk2.git
EDK2_REV=master
TF_RMM_REMOTE="https://jpbrucker.net/git/rmm"
TF_RMM_REV=origin/qemu-rme
MBEDTLS_REMOTE="https://github.com/Mbed-TLS/mbedtls.git"
MBEDTLS_REV=mbedtls-3.4.0
TF_A_REMOTE="https://jpbrucker.net/git/tf-a"
TF_A_REV=origin/qemu-rme
LINUX_CCA_HOST_REMOTE="https://git.gitlab.arm.com/linux-arm/linux-cca.git"
LINUX_CCA_HOST_REV=origin/cca-full/rmm-v1.0-eac2
LINUX_CCA_REALM_REMOTE="https://git.gitlab.arm.com/linux-arm/linux-cca.git"
LINUX_CCA_REALM_REV=origin/cca-full/rmm-v1.0-eac2
DTC_REMOTE="git://git.kernel.org/pub/scm/utils/dtc/dtc.git"
DTC_REV=origin/master
KVMTOOL_REMOTE="https://github.com/Havner/kvmtool-cca.git"
KVMTOOL_REV=origin/fvp-cca-2
KVM_UNIT_TESTS_REMOTE="https://gitlab.arm.com/linux-arm/kvm-unit-tests-cca"
KVM_UNIT_TESTS_REV=origin/cca/rfc-v1

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
QEMU_REMOTE=https://gitlab.com/qemu-project/qemu.git
QEMU_REV=master
QEMU_BIN="$QEMU/build/qemu-system-aarch64"


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
    rm -rf "$MBEDTLS"
    rm -rf "$TF_A"
    rm -rf "$LINUX_CCA_HOST"
    rm -rf "$LINUX_CCA_REALM"
    rm -rf "$DTC"
    rm -rf "$KVMTOOL"
    rm -rf "$KVM_UNIT_TESTS"
    rm -rf "$TOOLCHAINS"
    rm -rf "$FVP"
    rm -rf "$OUT"
}

function init_edk2() {
    start ${FUNCNAME[0]}
    git clone --recursive "$EDK2_REMOTE" "$EDK2"                        || stop
    pushd "$EDK2"
    git checkout --recurse-submodules -t -b fvp-cca $EDK2_REV           || stop
    touch .projectile
    popd
    success ${FUNCNAME[0]}
}

function init_tf_rmm() {
    start ${FUNCNAME[0]}
    git clone --recursive "$TF_RMM_REMOTE" "$TF_RMM"                    || stop
    pushd "$TF_RMM"
    git checkout -t -b fvp-cca $TF_RMM_REV                              || stop
    git submodule update --init --recursive                             || stop
    touch .projectile
    popd
    success ${FUNCNAME[0]}
}

function init_tf_a() {
    start ${FUNCNAME[0]}
    git clone "$MBEDTLS_REMOTE" "$MBEDTLS"                              || stop
    pushd "$MBEDTLS"
    git checkout -b fvp-cca $MBEDTLS_REV                                || stop
    touch .projectile
    popd
    git clone "$TF_A_REMOTE" "$TF_A"                                    || stop
    pushd "$TF_A"
    git checkout -t -b fvp-cca $TF_A_REV                                || stop
    touch .projectile
    popd
    success ${FUNCNAME[0]}
}

function init_linux_host() {
    start ${FUNCNAME[0]}
    git clone "$LINUX_CCA_HOST_REMOTE" "$LINUX_CCA_HOST"                || stop
    pushd "$LINUX_CCA_HOST"
    git checkout -t -b fvp-cca $LINUX_CCA_HOST_REV                      || stop
    touch .projectile
    cp -v "$PROVIDED/config-linux-host" "$LINUX_CCA_HOST/.config"       || stop
    popd
    success ${FUNCNAME[0]}
}

function init_linux_realm() {
    start ${FUNCNAME[0]}
    git clone "$LINUX_CCA_REALM_REMOTE" "$LINUX_CCA_REALM"              || stop
    pushd "$LINUX_CCA_REALM"
    git checkout -t -b fvp-cca $LINUX_CCA_REALM_REV                     || stop
    touch .projectile
    cp -v "$PROVIDED/config-linux-realm" "$LINUX_CCA_REALM/.config"     || stop
    patch -p1 < "$PROVIDED/linux-rsi-pages.patch"                       || stop
    popd
    success ${FUNCNAME[0]}
}

function init_dtc() {
    start ${FUNCNAME[0]}
    git clone "$DTC_REMOTE" "$DTC"                                      || stop
    pushd "$DTC"
    git checkout -t -b fvp-cca $DTC_REV                                 || stop
    touch .projectile
    popd
    success ${FUNCNAME[0]}
}

function init_kvmtool() {
    start ${FUNCNAME[0]}
    git clone "$KVMTOOL_REMOTE" "$KVMTOOL"                              || stop
    pushd "$KVMTOOL"
    git checkout -t -b fvp-cca $KVMTOOL_REV                             || stop
    touch .projectile
    popd
    success ${FUNCNAME[0]}
}

function init_kvm_unit_tests() {
    start ${FUNCNAME[0]}
    git clone "$KVM_UNIT_TESTS_REMOTE" "$KVM_UNIT_TESTS"                || stop
    pushd "$KVM_UNIT_TESTS"
    git checkout -t -b fvp-cca $KVM_UNIT_TESTS_REV                      || stop
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
    git checkout -t -b fvp-cca $QEMU_REV                                || stop
    git submodule update --init --recursive                             || stop
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
    cp -v "$PROVIDED/FVP_AARCH64_EFI.fd" "$OUT"                         || stop
    cp -v "$PROVIDED/QEMU_EFI.fd" "$OUT"                                || stop
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

# FIXME
function build_edk2() {
    start ${FUNCNAME[0]}
    pushd "$EDK2"
    source edksetup.sh
    make -j -C BaseTools                                                || stop
    export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
    bash build -b RELEASE -a AARCH64 -t GCC5 -p ArmVirtPkg/ArmVirtQemuKernel.dcs || stop
    popd
    unset GCC5_AARCH64_PREFIX
    success ${FUNCNAME[0]}
}

function build_tf_rmm() {
    start ${FUNCNAME[0]}
    save_path
    export PATH="$GCC_AARCH64_NONE_ELF_BIN:$PATH"
    export CROSS_COMPILE=aarch64-none-elf-
    pushd "$TF_RMM"
    cmake                                                               \
        -DRMM_CONFIG=qemu_virt_defcfg                                   \
        -DCMAKE_BUILD_TYPE=Debug                                        \
        -S .                                                            \
        -B build/                                                       || stop
    bear -a cmake --build build/                                        || stop
    cleanup_json
    cp -fv "$TF_RMM/build/Debug/rmm.img" "$OUT"                         || stop
    popd
    unset CROSS_COMPILE
    restore_path
    success ${FUNCNAME[0]}
}

function build_tf_a() {
    start ${FUNCNAME[0]}
    save_path
    export PATH="$GCC_AARCH64_NONE_ELF_BIN:$PATH"
    pushd "$TF_A"
    bear -a make CROSS_COMPILE=aarch64-none-elf-                        \
         PLAT=qemu                                                      \
         QEMU_USE_GIC_DRIVER=QEMU_GICV3                                 \
         ENABLE_RME=1                                                   \
         DEBUG=1                                                        \
         LOG_LEVEL=40                                                   \
         RMM="$OUT/rmm.img"                                             \
         BL33="$OUT/QEMU_EFI.fd"                                        \
         all fip                                                        || stop
    cleanup_json
    dd if="$TF_A/build/qemu/debug/bl1.bin" of="$TF_A/flash.bin"         || stop
    dd if="$TF_A/build/qemu/debug/fip.bin" of="$TF_A/flash.bin" seek=64 bs=4096 || stop
    #cp -fv "$TF_A/build/fvp/release/bl1.bin" "$OUT"                     || stop
    #cp -fv "$TF_A/build/fvp/release/fip.bin" "$OUT"                     || stop
    cp -fv "$TF_A/flash.bin" "$OUT"                                     || stop
    popd
    restore_path
    success ${FUNCNAME[0]}
}

function build_linux_host() {
    start ${FUNCNAME[0]}
    save_path
    export PATH="$GCC_AARCH64_NONE_LINUX_BIN:$PATH"
    pushd "$LINUX_CCA_HOST"
    bear -a make LOCALVERSION=""                                        \
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
    bear -a make LOCALVERSION=""                                        \
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
    bear -a make CC=aarch64-linux-gnu-gcc libfdt                        || stop
    cleanup_json
    popd
    success ${FUNCNAME[0]}
}

function build_kvmtool() {
    start ${FUNCNAME[0]}
    pushd "$KVMTOOL"
    # this is built using cross compiler (gcc9) from ubuntu, it crashes on gcc11 from arm
    bear -a make CROSS_COMPILE=aarch64-linux-gnu-                       \
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
    bear -a make                                                        || stop
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
    mformat -i "$BOOT_IMG" -n 64 -h 2 -T 65536 -v "BOOT IMG" -C ::      || stop
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
    bear make -j8                                                       || stop
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
}

function run() {
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
        -M virt,virtualization=on,secure=on,gic-version=3 \
        -M acpi=off -cpu max,x-rme=on,sme=off -m 3G -smp 8 \
        -nographic \
        -bios "$OUT/flash.bin" \
        -kernel "$OUT/Image" \
        -initrd "$OUT/initramfs-host.cpio.gz" \
        -device virtio-net-pci,netdev=net0 \
        -netdev tap,id=net0,ifname=cca0,script=no \
        -device virtio-9p-device,fsdev=shr0,mount_tag=FM \
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
  init_tf_rmm
  init_tf_a
  init_linux_host
  init_linux_realm
  init_dtc
  init_kvmtool
  init_kvm_unit_tests
  init_toolchains
  init_fvp
  init_out
  init           (does all the inits above excluding clean)
  build_tf_rmm
  build_tf_a
  build_linux_host
  build_linux_realm
  build_libfdt
  build_kvmtool
  build_kvm_unit_tests
  build_root_host
  build_root_realm
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
        if [[ "$1" = "init"* ]] || [[ "$1" = "build"* ]] || [[ "$1" = "net"* ]] || [[ "$1" == "run"* ]]; then
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
