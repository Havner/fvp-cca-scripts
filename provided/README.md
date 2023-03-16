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

## grub.cfg

Config for grub for the non secure world. Based on optee provided one.

## config-linux-host

Config for the linux kernel. Based on the one from islet with make oldconfig on
newer kernel.

## config-linux-realm

Config for the linux kernel running in real. Based on defconfig with lots of
unneeded drivers disabled.

## config-fvp

Configuration for running the FVP. Tried one from TF-A docs but it didn't
work. This one is from islet.

## run-lkvm.sh

Script for running realm linux on lkvm.

## hexdump.sh

Script for simple byte for byte formatting for hexdump.

## module.sh

Script to quickly reload the rsi kernel module.

# Other

## initramfs-host.tar.bz2

Simple initramfs for the non secure host. Based on busybox. Also taken from
islet for now. Might need to be reworked when we need some more tools
inside. For now it does the job. It works as the main rootfs.

## initramfs-realm.tar.bz2

Simple initramfs for the realm kernel. There is no root, initramfs should run
some shell. Taken from islet.
