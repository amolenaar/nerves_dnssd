#!/bin/sh

set -e

if [ "$1" -eq ""]
then
  echo "Usage: $0 <number>"
  echo "Number should be a positive integer between 0 and 99"
  exit 1
fi

export MIX_TARGET=qemu_arm

IMAGE=_build/qemu_arm-$1.img
KERNEL=~/.nerves/artifacts/nerves_system_qemu_arm-0.11.0.arm_unknown_linux_gnueabihf/images/zImage
DTB=~/.nerves/artifacts/nerves_system_qemu_arm-0.11.0.arm_unknown_linux_gnueabihf/images/vexpress-v2p-ca9.dtb

test -d deps/qemu_arm || mix deps.get

mix do firmware, firmware.image ${IMAGE}

qemu-system-arm -M vexpress-a9 -smp 1 -m 256 -kernel ${KERNEL} \
	-dtb ${DTB} \
	-drive file=${IMAGE},if=sd,format=raw \
	-append "console=ttyAMA0,115200 root=/dev/mmcblk0p2" \
	-serial stdio \
	-net nic,macaddr=52:54:00:12:34:$1 -net vde,sock=/tmp/switch1
