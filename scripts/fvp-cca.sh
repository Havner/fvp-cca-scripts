#!/bin/bash

SCRIPTS="`dirname $0`"
export ROOT="`realpath $SCRIPTS/..`"

export SCRIPTS="$ROOT/scripts"
export PROVIDED="$ROOT/provided"

export TF_RMM="$ROOT/1.tf-rmm"
export TF_A="$ROOT/2.tf-a"
export OPTEE_BUILD="$ROOT/3.optee-build"
export LINUX_CCA="$ROOT/4.linux-cca"
export LINUX_CCA_REALM="$ROOT/5.linux-cca-realm"
export DTCUTIL="$ROOT/6.dtcutil"
export KVMTOOL="$ROOT/7.kvmtool"

export TOOLCHAINS="$ROOT/toolchains"
export FVP="$ROOT/fvp"
export OUT="$ROOT/out"
export SHARED_DIR="$OUT/shared_dir"


export TF_RMM_REMOTE="https://git.trustedfirmware.org/TF-RMM/tf-rmm.git"
export TF_RMM_REV=origin/main
export TF_A_REMOTE="https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git"
export TF_A_REV=origin/master
export OPTEE_BUILD_REMOTE="https://github.com/OP-TEE/build.git"
export OPTEE_BUILD_REV=origin/master
export LINUX_CCA_REMOTE="https://git.gitlab.arm.com/linux-arm/linux-cca.git"
export LINUX_CCA_REV=origin/cca-host/rfc-v1
export LINUX_CCA_REALM_REMOTE="https://git.gitlab.arm.com/linux-arm/linux-cca.git"
export LINUX_CCA_REALM_REV=origin/cca-guest/rfc-v1
export DTCUTIL_REMOTE="git://git.kernel.org/pub/scm/utils/dtc/dtc.git"
export DTCUTIL_REV=origin/master
export KVMTOOL_REMOTE="https://gitlab.arm.com/linux-arm/kvmtool-cca"
export KVMTOOL_REV=origin/cca/rfc-v1

# https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
# for building tf-rmm and tf-a
export GCC_AARCH64_NONE_ELF=https://developer.arm.com/-/media/Files/downloads/gnu/11.3.rel1/binrel/arm-gnu-toolchain-11.3.rel1-x86_64-aarch64-none-elf.tar.xz
export GCC_ARM_NONE_EABI=https://developer.arm.com/-/media/Files/downloads/gnu/11.3.rel1/binrel/arm-gnu-toolchain-11.3.rel1-x86_64-arm-none-eabi.tar.xz
# for building linux kernel
export GCC_AARCH64_NONE_LINUX=https://developer.arm.com/-/media/Files/downloads/gnu/11.3.rel1/binrel/arm-gnu-toolchain-11.3.rel1-x86_64-aarch64-none-linux-gnu.tar.xz
export GCC_ARM_NONE_LINUX=https://developer.arm.com/-/media/Files/downloads/gnu/11.3.rel1/binrel/arm-gnu-toolchain-11.3.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz

function gcc_print_bin() {
	echo "$TOOLCHAINS/`basename "$1" | sed -s 's#\.tar\.xz##g'`/bin"
}

export GCC_AARCH64_NONE_ELF_BIN=`gcc_print_bin "$GCC_AARCH64_NONE_ELF"`
export GCC_ARM_NONE_EABI_BIN=`gcc_print_bin "$GCC_ARM_NONE_EABI"`
export GCC_AARCH64_NONE_LINUX_BIN=`gcc_print_bin "$GCC_AARCH64_NONE_LINUX"`
export GCC_ARM_NONE_LINUX_BIN=`gcc_print_bin "$GCC_ARM_NONE_LINUX"`

export FVP_BASE_REVC=https://developer.arm.com/-/media/Files/downloads/ecosystem-models/FVP_Base_RevC-2xAEMvA_11.18_16_Linux64.tgz
export FVP_SUBDIR=Base_RevC_AEMvA_pkg/models/Linux64_GCC-9.3


function save_path() {
	export OLDPATH=$PATH
}

function restore_path() {
	export PATH=$OLDPATH
	unset OLDPATH
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
	rm -rf "$TF_RMM"
	rm -rf "$TF_A"
	rm -rf "$OPTEE_BUILD"
	rm -rf "$LINUX_CCA"
	rm -rf "$LINUX_CCA_REALM"
	rm -rf "$DTCUTIL"
	rm -rf "$KVMTOOL"
	rm -rf "$TOOLCHAINS"
	rm -rf "$FVP"
	rm -rf "$OUT"
}

function init_tf_rmm() {
	start init_tf_rmm
	git clone --recursive "$TF_RMM_REMOTE" "$TF_RMM"            || stop
	pushd "$TF_RMM"
	git checkout --recurse-submodules -t -b fvp-cca $TF_RMM_REV || stop
	popd
	success init_tf_rmm
}

function init_tf_a() {
	start init_tf_a
	git clone "$TF_A_REMOTE" "$TF_A"                            || stop
	pushd "$TF_A"
	git checkout -t -b fvp-cca $TF_A_REV                        || stop
	popd
	success init_tf_a
}

function init_optee_build() {
	start init_optee_build
	git clone "$OPTEE_BUILD_REMOTE" "$OPTEE_BUILD"              || stop
	pushd "$OPTEE_BUILD"
	git checkout -t -b fvp-cca $OPTEE_BUILD_REV                 || stop
	patch -p1 < "$PROVIDED/optee-build.patch"                   || stop
	popd
	success init_optee_build
}

function init_linux_cca() {
	start init_linux_cca
	git clone "$LINUX_CCA_REMOTE" "$LINUX_CCA"                  || stop
	pushd "$LINUX_CCA"
	git checkout -t -b fvp-cca $LINUX_CCA_REV                   || stop
	cp -v "$PROVIDED/config-linux" "$LINUX_CCA/.config"         || stop
	popd
	success init_linux_cca
}

function init_linux_cca_realm() {
	start init_linux_cca_realm
	git clone "$LINUX_CCA_REALM_REMOTE" "$LINUX_CCA_REALM"      || stop
	pushd "$LINUX_CCA_REALM"
	git checkout -t -b fvp-cca $LINUX_CCA_REALM_REV             || stop
	cp -v "$PROVIDED/config-linux-realm" "$LINUX_CCA_REALM/.config" || stop
	popd
	success init_linux_cca_realm
}

function init_dtcutil() {
	start init_dtcutil
	git clone "$DTCUTIL_REMOTE" "$DTCUTIL"                      || stop
	pushd "$DTCUTIL"
	git checkout -t -b fvp-cca $DTCUTIL_REV                     || stop
	popd
	success init_dtcutil
}

function init_kvmtool() {
	start init_kvmtool
	git clone "$KVMTOOL_REMOTE" "$KVMTOOL"                      || stop
	pushd "$KVMTOOL"
	git checkout -t -b fvp-cca $KVMTOOL_REV                     || stop
	popd
	success init_kvmtool
}

function init_toolchains() {
	start init_toolchains
	mkdir "$TOOLCHAINS"                                         || stop
	pushd "$TOOLCHAINS"
	for LINK in "$GCC_AARCH64_NONE_ELF" "$GCC_ARM_NONE_EABI" "$GCC_AARCH64_NONE_LINUX" "$GCC_ARM_NONE_LINUX"; do
		wget "$LINK"                                            || stop
		tar xf `basename "$LINK"`                               || stop
	done
	# Those symlinks are used by optee-build
	ln -s `basename "$GCC_AARCH64_NONE_LINUX" | sed -e 's#\.tar\.xz##g'` aarch64 || stop
	ln -s `basename "$GCC_ARM_NONE_LINUX" | sed -e 's#\.tar\.xz##g'` aarch32     || stop
	popd
	success init_toolchains
}

function init_fvp() {
	start init_fvp
	mkdir "$FVP"                                                || stop
	pushd "$FVP"
	wget "$FVP_BASE_REVC"                                       || stop
	tar xf `basename "$FVP_BASE_REVC"`                          || stop
	cp -v "$PROVIDED/config-fvp" "$FVP/$FVP_SUBDIR"                || stop
	popd
	success init_fvp
}

function init_out() {
	start init_out
	mkdir "$OUT"                                                || stop
	mkdir "$SHARED_DIR"                                         || stop
	cp -v "$PROVIDED/FVP_AARCH64_EFI.fd" "$OUT"                 || stop
	cp -v "$PROVIDED/bootaa64.efi" "$OUT"                       || stop
	cp -v "$PROVIDED/rootfs.tar.bz2" "$OUT"                     || stop
	cp -v "$PROVIDED/initramfs-busybox-aarch64.cpio.gz" "$SHARED_DIR" || stop
	cp -v "$PROVIDED/run-lkvm.sh" "$SHARED_DIR"                 || stop
	success init_out
}

function init() {
	init_clean
	init_tf_rmm
	init_tf_a
	init_optee_build
	init_linux_cca
	init_linux_cca_realm
	init_dtcutil
	init_kvmtool
	init_toolchains
	init_fvp
	init_out
}

function build_tf_rmm() {
	start build_tf_rmm
	save_path
	export PATH="$GCC_AARCH64_NONE_ELF_BIN:$PATH"
	export CROSS_COMPILE=aarch64-none-elf-
	pushd "$TF_RMM"
	cmake -DRMM_CONFIG=fvp_defcfg -S . -B build/                || stop
	cmake --build build/                                        || stop
	cp -fv "$TF_RMM/build/Release/rmm.img" "$OUT"               || stop
	popd
	unset CROSS_COMPILE
	restore_path
	success build_tf_rmm
}

function build_tf_a() {
	start build_tf_a
	save_path
	export PATH="$GCC_AARCH64_NONE_ELF_BIN:$PATH"
	pushd "$TF_A"
	make CROSS_COMPILE=aarch64-none-elf- \
		 PLAT=fvp \
		 ENABLE_RME=1 \
		 DEBUG=1 \
		 FVP_HW_CONFIG_DTS=fdts/fvp-base-gicv3-psci-1t.dts \
		 RMM="$OUT/rmm.img" \
		 BL33="$OUT/FVP_AARCH64_EFI.fd" \
		 all fip                                                || stop
	cp -fv "$TF_A/build/fvp/debug/bl1.bin" "$OUT"               || stop
	cp -fv "$TF_A/build/fvp/debug/fip.bin" "$OUT"               || stop
	popd
	restore_path
	success build_tf_a
}

function build_linux_ns() {
	start build_linux_ns
	pushd "$OPTEE_BUILD"
	make -j8 -f fvp.mk linux                                    || stop
	cp -fv "$LINUX_CCA/arch/arm64/boot/Image" "$OUT"            || stop
	cp -fv "$LINUX_CCA/arch/arm64/boot/dts/arm/fvp-base-revc.dtb" "$OUT" || stop
	make -j8 -f fvp.mk boot-img2                                || stop
	popd
	success build_linux_ns
}

function build_linux_realm() {
	start build_linux_realm
	save_path
	export PATH="$GCC_AARCH64_NONE_LINUX_BIN:$PATH"
 	pushd "$LINUX_CCA_REALM"
 	make CROSS_COMPILE=aarch64-none-linux-gnu- \
		 ARCH=arm64 \
		 -j8                                                    || stop
	cp -fv "$LINUX_CCA_REALM/arch/arm64/boot/Image" "$SHARED_DIR/Image.realm" || stop
	popd
	restore_path
	success build_linux_realm
}

function build_libfdt() {
	start build_libfdt
	pushd "$DTCUTIL"
	# this is built using cross compiler (gcc9) from ubuntu
	make CC=aarch64-linux-gnu-gcc libfdt                        || stop
	popd
	success build_libfdt
}

function build_kvmtool() {
	start build_kvmtool
	pushd "$KVMTOOL"
	# this is built using cross compiler (gcc9) from ubuntu, it crashes on gcc11 from arm
	make CROSS_COMPILE=aarch64-linux-gnu- \
		 ARCH=arm64 \
		 LIBFDT_DIR="$DTCUTIL/libfdt"                           || stop
	cp -fv "$KVMTOOL/lkvm" "$SHARED_DIR"                        || stop
	popd
	success build_kvmtool
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
	build_linux_ns
	build_linux_realm
	build_libfdt
	build_kvmtool
}

function run() {
	start running
	pushd "$FVP/$FVP_SUBDIR"
	./FVP_Base_RevC-2xAEMvA                                 \
		-f config-fvp                                       \
		-Q 1000                                             \
		-C bp.secureflashloader.fname="$OUT/bl1.bin"        \
		-C bp.flashloader0.fname="$OUT/fip.bin"             \
		-C bp.virtioblockdevice.image_path="$OUT/boot.img"  \
		-C bp.virtiop9device.root_path="$SHARED_DIR"            || stop
	popd
}

function usage() {
	echo "Run with a target function name for what you intend to do.

Possible targets are:
  init_clean
  init_tf_rmm
  init_tf_a
  init_optee_build
  init_linux_cca
  init_linux_cca_realm
  init_dtcutil
  init_kvmtool
  init_toolchains
  init_fvp
  init_out
  init           (does all the inits above including clean)
  build_tf_rmm
  build_tf_a
  build_linux_ns
  build_linux_realm
  build_libfdt
  build_kvmtool
  build          (does all the builds above in the correct order)
  run

Running without argument does:
  build
  run

Initialization should be performed just once."
}

if [ "$#" -gt 1 ]; then
	echo "Maximum of one argument is accepted."
	echo "Run with -h or --help to see usage."
	exit 1
fi

if [ "$1" == "-h" -o "$1" == "--help" ]; then
	usage
	exit 0
fi

if [[ "$1" = "init"* ]] || [[ "$1" = "build"* ]] || [ "$1" == "run" ]; then
	eval "$1"
elif [ "$1" ]; then
	echo "Wrong argument passed."
	echo "Run with -h or --help to see usage."
	exit 1
else
	build
	run
fi
