#!/bin/sh

set -e

if [ ! -x /tmp/switch1 ]
then
  echo "VDE switch is not present. Start with:"
  echo "\tvde_switch -F -sock /tmp/switch1"
  echo "\tslirpvde -s /tmp/switch1 -dhcp"
  exit 1
fi

if [ "$1" == "" ]
then
  MAC=$(($RANDOM % 99))
  echo "Assigning random MAC address (...:${MAC})"
else
  MAC=$1
  echo "Assigning MAC address (...:${MAC})"
fi


export MIX_TARGET=qemu_arm
QEMU_ARM_VERSION=0.11.0

IMAGE=_build/qemu_arm-$MAC.img
KERNEL=~/.nerves/artifacts/nerves_system_qemu_arm-${QEMU_ARM_VERSION}.arm_unknown_linux_gnueabihf/images/zImage
DTB=~/.nerves/artifacts/nerves_system_qemu_arm-${QEMU_ARM_VERSION}.arm_unknown_linux_gnueabihf/images/vexpress-v2p-ca9.dtb

test -d deps/qemu_arm || mix deps.get

mix do firmware, firmware.image ${IMAGE}

qemu-system-arm -M vexpress-a9 -smp 1 -m 256 -kernel ${KERNEL} \
	-dtb ${DTB} \
	-drive file=${IMAGE},if=sd,format=raw \
	-append "console=ttyAMA0,115200 root=/dev/mmcblk0p2" \
	-serial stdio \
	-net nic,macaddr=52:54:00:12:34:$MAC -net vde,sock=/tmp/switch1
