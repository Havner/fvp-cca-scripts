# Why

Files in this folders are either configs or some precompiled binaries.

Binaries are usually files that are both:
- of little consequence to the grand overall scheme of things
- are harder to compile/source/prepare

Over time those files should be removed and replaced with properly sourced and
compiled stuff.

# Precompiled files

## FVP_AARCH64_EFI.fd

This is a compiled EFI firmware/bios. Its main purpose is to load grub.efi
binary. This file is compiled from edk2-platforms (most probably
ArmVExpress-FVP-AArch64). Optee build does that. Unfortunately the one I
compiled doesn't work, probably wrong FVP. The one provided comes from islet
precompiled assets.

## bootaa64.efi

This is grub EFI binary. Can be compiled from grub sources, but may have some
external dependencies. For the build process optee-build can be checked. Have
not dived deep into that. The one provided comes from islet precompiled assets.

# Config files

## optee-build.patch

A patch for the optee-build system (it creates the non secure kernel and image)
for correct paths, image creation, grub config and the like.

## config-linux

Config for the linux kernel. Based on the one from islet with make oldconfig on
newer kernel.

## config-linux-realm

Config for the linux kernel running in real. Based on the one from islet with
make oldconfig on newer kernel.

## config-fvp

Configuration for running the FVP. Tried one from TF-A docs but it didn't
work. This one is from islet.

## run-lkvm.sh

Script for running realm linux on lkvm.

# Other

## rootfs.tar.bz2

Simple rootfs for the non secure host. Based on busybox. Also taken from islet
for now. Might need to be reworked when we need some more tools inside. For now
it does the job.

## initramfs-busybox-aarch64.cpio.gz

Simple initramfs for the realm kernel. There is no root, initramfs should run
some shell. Taken from islet.