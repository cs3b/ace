#!/bin/sh
set -eu
# Own Debian kernel; no networking, host directory shares, or credentials.
/opt/homebrew/bin/qemu-system-aarch64 -M virt -accel hvf -cpu host -smp 2 -m 2048 -nic none -display none -serial file:guest-console-hvf.log -no-reboot -kernel vmlinuz -initrd initrd -drive if=none,file=installed-rootfs.img,format=raw,id=root -device virtio-blk-device,drive=root -append 'root=/dev/vda noresume rw rootfstype=ext4 console=ttyAMA0 init=/sbin/ace-fixture-init'
