#!/bin/bash
# refrence: https://www.cnblogs.com/phoebus-ma/p/17437257.html
# Copyright (c) 2024 dylane chen
# Author: Tao Chen <chen.dylane@gmail.com>
# test version: QEMU emulator version 8.2.2 (Debian 1:8.2.2+ds-0ubuntu1)

program="$0"
arch="x86_64"
kernel=""
rootfs=""
smp=1
mem=1024
debug=""

usage() {
    echo "Usage: ${progname} [options...] <arch> <kernel><smp><mem>"
    echo
    echo "start qemu quickly"
    echo
    echo "Options:"
    echo
    echo "  --kernel=<bzImage>  use 'bzImage' as kernel image"
    echo "  --rootfs=<file>     use 'file' as rootfs image"
    echo "  --smp=<smp>         amount of guest smp"
    echo "                      (default:${smp})"
    echo "  --mem=<mem>         maximum amount of guest memory"
    echo "                      (default:${mem}(1G))"
    echo "  --quit              force quit qemu"
    echo "  --debug             run with debug mode"
    echo
    echo "Example:"
    echo
    echo " ${progname} --arch=amd64 --kernel=linux-next/arch/x86_64/boot/bzImage --rootfs=code/ubuntu24-base.ext4 --smp=2 --mem=2048"
    echo
}

while getopts ":h-:" optchar; do
    case "${optchar}" in
    -)
        case "${OPTARG}" in
        kernel=*)
            kernel="${OPTARG#*=}"
            ;;
        rootfs=*)
            rootfs="${OPTARG#*=}"
            ;;
        arch=*)
            arch="${OPTARG#*=}"
            ;;
        smp=*)
            smp="${OPTARG#*=}"
            ;;
        mem=*)
            mem="${OPTARG#*=}"
            ;;
        quit)
            for pid in $(ps -ef | grep "qemu-system" | awk '{print $2}')
            do
                sudo kill -9 $pid
            done
            exit 0
            ;;
        debug)
            debug="-s -S"
            ;;
        arch | kernel | smp | mem | rootfs)
            echo "${progname}: option --${OPTARG} requires an argument." >&2
            usage >&2
            ;;
        help)
            usage
            exit 0
            ;;
        *)
            echo "${progname}: unknown option --${OPTARG}" >&2
            usage >&2
            exit 1
            ;;
        esac
        ;;
    h)
        usage
        exit 0
        ;;
    *)
        echo "${progname}: unknown option -${OPTARG}" >&2
        usage >&2
        exit 1
        ;;
    esac
done

if [ -n "${rootfs}" ] && [ -n "${kernel}" ]; then
    qemu-system-${arch} -m ${mem} \
        -nographic -smp ${smp} \
        -kernel ${kernel} \
        -append "noinintrd console=ttyS0 crashkernel=256M root=/dev/vda rootfstype=ext4 rw loglevel=8" \
        -drive if=none,file=${rootfs},id=hd0 \
        -device virtio-blk-pci,drive=hd0 \
        -netdev user,id=mynet \
        -device virtio-net-pci,netdev=mynet \
        ${debug} \
        #share file from host to guest
        #-fsdev local,id=kmod_dev,path=./kmodules,security_model=none \
        #-device virtio-9p-pci,fsdev=kmod_dev,mount_tag=kmod_mount
else
    echo "rootfs:${rootfs} or kernel:${kernel} not set"
fi
