#!/bin/sh

./lkvm run                                           \
	   --debug                                       \
	   --realm                                       \
	   --measurement-algo="sha256"                   \
	   --disable-sve                                 \
	   --console serial                              \
	   --irqchip=gicv3                               \
	   -m 256M                                       \
	   -c 1                                          \
	   -k Image.realm                                \
	   -i initramfs-busybox-aarch64.cpio.gz          \
	   -p "earlycon=ttyS0 printk.devkmsg=on"
