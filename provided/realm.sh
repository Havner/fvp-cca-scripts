#!/bin/sh

cd /shared

./lkvm run                                                              \
       --debug                                                          \
       --realm                                                          \
       --measurement-algo="sha256"                                      \
       --disable-sve                                                    \
       --console serial                                                 \
       --irqchip=gicv3                                                  \
       -m 256M                                                          \
       -c 1                                                             \
       -k Image.realm                                                   \
       -i initramfs-realm.cpio.gz                                       \
       -p "earlycon=ttyS0 printk.devkmsg=on"                            \
       -n virtio                                                        \
       --9p /shared,FMR                                                 \
       "$@"

# Local Variables:
# indent-tabs-mode: nil
# End:
