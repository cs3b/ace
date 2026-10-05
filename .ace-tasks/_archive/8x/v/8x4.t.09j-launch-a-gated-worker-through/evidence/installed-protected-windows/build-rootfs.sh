#!/bin/sh
set -eu
# Run from this fixture directory; source gems are built from frozen source first.
# This copies no credentials or host runtime state.
# Existing owned export contains immutable installed gems; overlay fixture scripts only.
docker run --rm -v "$PWD:/out" ace-09j-vm-toolchain:local sh -c 'mkdir /guest; tar -xf /out/installed-rootfs.tar -C /guest; cp /out/guest-probe.py /guest/opt/ace-fixture/guest-probe.py; cp /out/phase-client.rb /guest/opt/ace-fixture/phase-client.rb; cp /out/diagnostic.rb /guest/opt/ace-fixture/diagnostic.rb; cp /out/guest-init /guest/sbin/ace-fixture-init; chmod 755 /guest/sbin/ace-fixture-init; mkdir -p /guest/dev /guest/proc /guest/sys /guest/run; truncate -s 2G /out/installed-rootfs.img; mkfs.ext4 -q -F -d /guest /out/installed-rootfs.img; cp /boot/vmlinuz-6.1.0-53-arm64 /out/vmlinuz; cp /boot/initrd.img-6.1.0-53-arm64 /out/initrd'
