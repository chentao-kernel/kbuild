#!/bin/bash
#
# Refrence: https://github.com/ZubairLK/mkdebianrfs/blob/master/mkdebianrfs.sh
# Copyright (c) 2013 Imagination Technologies
# Author: Alex Smith <alex.smith@imgtec.com>
#
# Creates a Debian root FS using debootstrap and configures it such that it is
# usable to boot a system.
#
# This script requires a statically linked version of QEMU for the target
# architecture to be available in PATH (named qemu-<arch>-static), and
# configured via binfmt_misc to be used to execute binaries for the target
# architecture. This is needed to perform second stage configuration of the
# target system.
#
# If the host system is running a Debian-based distro, the required packages
# can be installed with:
#
#   $ apt-get install binfmt-support qemu qemu-user-static debootstrap
#
# This will install QEMU and automatically configure binfmt_misc.
#
# TODO:
#  - Make it possible to run this completely non-interactively by allowing
#    configuration such as the root password, locale, timezone, etc to be
#    specified as arguments.
#  - Command line option for serial console configuration (just sets up ttyS0
#    at 115200 for now).
#  - Option for network configuration (just configures DHCP on eth0).
#

progname="$0"

debian_packages="locales"
#debian_mirror="http://ftp.uk.debian.org/debian/"
debian_mirror="$(sudo cat /etc/apt/sources.list | grep "^deb http" | awk ' NR==1 {print $2}')"

if [ -z "${debian_mirror}" ];then
	echo "debian_mirror not found:${debian_mirror}, use: http://archive.ubuntu.com/ubuntu/"
	debian_mirror="http://archive.ubuntu.com/ubuntu/"
fi

debian_path="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
#target_tar="debian-wheezy-mipsel.tar.bz2"
target_tar=""
target_dir="/mnt"
target_arch="amd64"

usage() {
    echo "Usage: ${progname} [options...] <arch> <dist> <target>"
    echo
    echo "Creates a Debian root FS from the specified <dist> (e.g. stable,"
    echo "wheezy, testing, etc.) for <arch> using debootstrap and configures"
    echo "it such that it is bootable. Unless --tar is specified (see below),"
    echo "<target> will be taken as a directory name to create the root FS in."
    echo
    echo "Options:"
    echo
    echo "  --tar=<**tar.bz2>    Create a tar file instead of installing to a"
    echo "                       directory. In this case, <target> specifies"
    echo "                       the name of the output file, which will be"
    echo "                       compressed based on its file extension."
    echo "  --dir=</mnt>         Target dir to mount rootfs."
    echo "  --include=<packages> Specifies a list (comma separated) of extra"
    echo "                       packages to install in the filesystem."
    echo "  --mirror=<mirror>    URL of Debian mirror to use"
    echo "                       (defaults to ${debian_mirror})."
    echo "  --dist=<dist>        release version like: wheezy"
    echo "                       (defaults to ${target_dist})."
    echo
    echo "Example:"
    echo
    echo "sudo bash build_rootfs.sh --arch=amd64 --dist=focal --mirror=http://mirrors.jdcloudcs.com/ubuntu --tar=ubuntu_focal_amd64.tar.bz"
    echo "sudo bash build_rootfs.sh --arch=arm64 --dist=focal --mirror=https://mirrors.ustc.edu.cn/ubuntu-ports/ --tar=ubuntu_focal_arm64.tar.bz"
    echo ""
    echo
}

die() {
    echo "${progname}: $@" >&2
    exit 1
}

prepare_install() {
    sudo apt-get install binfmt-support qemu qemu-user-static debootstrap -y
}

while getopts ":h-:" optchar; do
    case "${optchar}" in
    -)
        case "${OPTARG}" in
        tar=*)
            target_tar="${OPTARG#*=}"
            ;;
	    dir=*)
            target_dir="${OPTARG#*=}"
            ;;
        include=*)
            debian_packages="${debian_packages},${OPTARG#*=}"
            ;;
        mirror=*)
            debian_mirror="${OPTARG#*=}"
            ;;
        arch=*)
            target_arch="${OPTARG#*=}"
            ;;
        dist=*)
            target_dist="${OPTARG#*=}"
            ;;
        arch | dist | include | dir)
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

shift $((OPTIND-1))

[ -z "${target_arch}" ] && die "invalid argument"
[ -z "${target_dist}" ] && die "invalid argument"

[ $UID -ne 0 ] && die "must be run as root"
[ -z "`which debootstrap`" ] && die "cannot find debootstrap"

# QEMU gets copied into /usr/bin in the target filesystem. Need to have
# binfmt_misc configured to use that path.
#target_qemu=`which qemu-${target_arch}-static`
#[ -z "${target_qemu}" ] && die "cannot find qemu-${target_arch}-static"
#grep -Rq "/usr/bin/qemu-${target_arch}-static" /proc/sys/fs/binfmt_misc/ \
#    2>/dev/null || \
#        die "/usr/bin/qemu-${target_arch}-static not configured with binfmt_misc"

#set -e

# If creating a tar file, install to a temporary directory.
if [ -n "${target_tar}" ]; then
    tar_dir="${target_tar%.tar*}"
    [ -z "${tar_dir}" -o "${target_tar}" = "${tar_dir}" ] && \
        die "output file name is invalid"

    tmp_dir=`mktemp -d`
    target_dir="${tmp_dir}/${tar_dir}"
    mkdir "${target_dir}"
else
    target_dir=`readlink -e "$target_dir" || true`
    [ -z "${target_dir}" ] && die "directory '$3' does not exist"
    chown root:root "${target_dir}"
fi

# Register a cleanup handler.
cleanup() {
    set +e

    umount "${target_dir}/proc" >/dev/null 2>&1
    umount "${target_dir}/sys" >/dev/null 2>&1

    if [ -n "${target_tar}" ]; then
        echo "Removing ${tmp_dir}..."
        rm -rf "${tmp_dir}"
    fi

    trap - EXIT INT TERM
}
trap "cleanup; exit 1;" INT TERM
trap "cleanup;" EXIT

echo
echo "Creating Debian ${target_dist} RFS for ${target_arch} in '${target_dir}'..."
echo

# first step
debootstrap --foreign --arch="${target_arch}" --include="${debian_packages}" \
    "${target_dist}" "${target_dir}" "${debian_mirror}"

echo
echo "Configuring packages..."
echo

cp "${target_qemu}" "${target_dir}/usr/bin/qemu-${target_arch}-static"

#second step
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C \
    LANGUAGE=C LANG=C PATH="${debian_path}" chroot "${target_dir}" \
    /debootstrap/debootstrap --second-stage
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C \
    LANGUAGE=C LANG=C PATH="${debian_path}" chroot "${target_dir}" \
    dpkg --configure -a

echo
echo "Configuring target system..."
echo

# Create root password.
echo "Please enter a password for the root user:"
PATH="${debian_path}" chroot "${target_dir}" passwd root

# Configure locale and time zone.
LC_ALL=C LANGUAGE=C LANG=C PATH="${debian_path}" chroot "${target_dir}" \
    dpkg-reconfigure locales
LC_ALL=C LANGUAGE=C LANG=C PATH="${debian_path}" chroot "${target_dir}" \
    dpkg-reconfigure tzdata

# Configure a serial console.
echo "T0:23:respawn:/sbin/getty -L ttyS0 115200 vt100" >> \
    "${target_dir}/etc/inittab"

# Configure a host name.
echo "debian" > "${target_dir}/etc/hostname"

# Configure networking.
# Change the interface name eth0 in guest os
if [ -f "${target_dir}/etc/network/interfaces" ];then
    echo "auto eth0" >> "${target_dir}/etc/network/interfaces"
    echo "allow-hotplug eth0" >> "${target_dir}/etc/network/interfaces"
    echo "iface eth0 inet dhcp" >> "${target_dir}/etc/network/interfaces"
else
    sudo cat > ${target_dir}/etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
EOF
fi

# Configure APT.
sources_list="${target_dir}/etc/apt/sources.list"
echo "deb ${debian_mirror} ${target_dist} main" > "${sources_list}"
echo "deb-src ${debian_mirror} ${target_dist} main" >> "${sources_list}"
case "${target_dist}" in
experimental|unstable|sid)
    # No updates here.
    ;;
*)
    echo >> "${sources_list}"
    echo "deb ${debian_mirror} ${target_dist}-updates main" >> \
        "${sources_list}"
    echo "deb-src ${debian_mirror} ${target_dist}-updates main" >> \
        "${sources_list}"
#    echo >> "${sources_list}"
#    echo "deb http://security.debian.org/ ${target_dist}/updates main" >> \
#        "${sources_list}"
#    echo "deb-src http://security.debian.org/ ${target_dist}/updates main" >> \
#        "${sources_list}"
    ;;
esac

# Let the user do any additional configuration.
echo
echo "Entering target system for additional configuration. Type 'exit' when done."
echo
PATH="${debian_path}" chroot "${target_dir}" /bin/bash

# Clean up.
chroot "${target_dir}" apt-get clean
rm -f "${target_dir}/usr/bin/qemu-${target_arch}-static"

if [ -n "${target_tar}" ]; then
    echo "Creating ${target_tar}..."
    tar -capf "${target_tar}" -C "${tmp_dir}" "${tar_dir}"
fi

# Create rootfs img
echo "Create rootfs img..."

if [ ! -f "rootfs_debian_${target_arch}.ext4" ];then
    dd if=/dev/zero of=rootfs_debian_${target_arch}.ext4 bs=1M count=1000
fi

if [ -f "rootfs_debian_${target_arch}.ext4" ];then
    mkfs.ext4 rootfs_debian_${target_arch}.ext4
    mkdir -p tmpfs
    mount -t ext4 rootfs_debian_${target_arch}.ext4 tmpfs/ -o loop
    cp -af ${target_dir}/* tmpfs/

    # no mount dev, the guest os will panic when mount rootfs
    # [    3.529263] /dev/root: Can't open blockdev
    # [    3.530075] VFS: Cannot open root device "/dev/vda" or unknown-block(0,0): error -6
    # [    3.530291] Please append a correct "root=" boot option; here are the available partitions:
    # [    3.531027] 0b00         1048575 sr0
    # refrence: https://www.cnblogs.com/phoebus-ma/p/17437257.html
    sudo mount -o bind /dev tmpfs/dev
    sudo mount -o bind /dev/pts tmpfs/dev/pts
    sudo umount tmpfs/dev/pts
    sudo umount tmpfs/dev

    umount tmpfs
    chmod 777 rootfs_debian_${target_arch}.ext4
else
    echo "${target_arch} not found"
fi


cleanup
echo "Done!"
