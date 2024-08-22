# kbuild
* build for linux kernel with container env
* build mini os based on latest kernel and ubuntu rootfs run in qemu
# Quick Start
## Env
ubuntu 24.04 run in vmware
## build container to compile kernel
build container use build_containers.sh,
build kenrel with gcc 13, clang 13, and use ubuntu 23.04 docker image
```
sudo bash build_containers.sh -g 13 -c 13 -u 23.04

Hey, we gonna use sudo for running docker
GCC VERSION:13,CLANG VERSION:13,UBUNTU VERSION:23.04

Building a container with CLANG_VERSION=13 and GCC_VERSION=13 from UBUNTU_VERSION=23.04
DEPRECATED: The legacy builder is deprecated and will be removed in a future release.
            Install the buildx component to build images with BuildKit:
```
finally images successfully builded show
```
...
Removing intermediate container da4b0a463bb7
 ---> 58fcca287fc2
Successfully built 58fcca287fc2
Successfully tagged kernel-build-container:gcc-13-clang-13
```
## build kernel
build kernel use main.py to set kernel source path, output path, target contaer, etc.
```
sudo python3 main.py -a x86_64 -k /boot/config-5.15.0-60-generic -s /home/dylane/code/linux -o /home/tmp -c gcc-13-clang-13 -- -j$(nproc)
```
building result
```
=== Building with gcc-13-clang-13 ===
Output subdirectory for this build: /home/tmp/config-5.15.0-60-generic-x86_64-gcc-13-clang-13
Output subdirectory doesn't exist, create it
No ".config", copy "/boot/config-5.15.0-60-generic" to "/home/tmp/config-5.15.0-60-generic-x86_64-gcc-13-clang-13/.config"
Going to save build log to "build_log.txt" in output subdirectory
Run the container: bash ./start_containers.sh gcc-13-clang-13 /home/dylane/code/linux /home/tmp/config-5.15.0-60-generic-x86_64-gcc-13-clang-13 -n -- make O=../out/ -j2 2>&1
    Hey, we gonna use sudo for running docker
    Run docker in NON-interactive mode
    Starting "kernel-build-container:gcc-13-clang-13"
    Mount source code directory "/home/dylane/code/linux" at "/home/root/src"
    Mount build output directory "/home/tmp/config-5.15.0-60-generic-x86_64-gcc-13-clang-13" at "/home/root/out"
    Gonna run command "make O=../out/ -j2 2>&1"
    
    make[1]: Entering directory '/home/root/out'
      SYNC    include/config/auto.conf.cmd
      GEN     Makefile
      HOSTCC  scripts/basic/fixdep
      HOSTCC  scripts/kconfig/confdata.o
      HOSTCC  scripts/kconfig/conf.o
      HOSTCC  scripts/kconfig/expr.o
      LEX     scripts/kconfig/lexer.lex.c
      YACC    scripts/kconfig/parser.tab.[ch]
      HOSTCC  scripts/kconfig/menu.o
      HOSTCC  scripts/kconfig/parser.tab.o
      ...
```
compile result log
```
/home/tmp/config-5.15.0-60-generic-x86_64-gcc-13-clang-13/build_log.txt
```
if you want add ebpf btf file in /sys/kernel/btf path, you can add these config options
```
#
# Compile-time checks and compiler options
#
CONFIG_DEBUG_INFO=y
# CONFIG_DEBUG_INFO_NONE is not set
# CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT is not set
# CONFIG_DEBUG_INFO_DWARF4 is not set
CONFIG_DEBUG_INFO_DWARF5=y
# CONFIG_DEBUG_INFO_REDUCED is not set
CONFIG_DEBUG_INFO_COMPRESSED_NONE=y
# CONFIG_DEBUG_INFO_COMPRESSED_ZLIB is not set
# CONFIG_DEBUG_INFO_COMPRESSED_ZSTD is not set
# CONFIG_DEBUG_INFO_SPLIT is not set
CONFIG_DEBUG_INFO_BTF=y
CONFIG_PAHOLE_HAS_SPLIT_BTF=y
CONFIG_PAHOLE_HAS_LANG_EXCLUDE=y
CONFIG_DEBUG_INFO_BTF_MODULES=y
```
## build rootfs
build rootfs use build_rootfs.sh, the rootfs based on ubuntu/debian
```
sudo bash build_rootfs2.sh --arch=amd64 --dist=noble --tar=ubuntu-noble-amd64.tar.bz2 --include=net-tools
```
building result
```
debian_mirror not found:, use: http://archive.ubuntu.com/ubuntu/

Creating Debian noble RFS for amd64 in '/tmp/tmp.R6X0DH3gJl/ubuntu-noble-amd64'...

I: Retrieving InRelease
I: Checking Release signature
I: Valid Release signature (key id F6ECB3762474EDA9D21B7022871920D1991BC93C)
I: Retrieving Packages
I: Validating Packages
I: Resolving dependencies of required packages...
I: Resolving dependencies of base packages...
I: Checking component main on http://archive.ubuntu.com/ubuntu...
I: Retrieving adduser 3.137ubuntu1
I: Validating adduser 3.137ubuntu1
```
at last you will see the  rootfs_debian_amd64.ext4 img
```
dylane@2404:~/code/kbuild$ ls
build_containers.sh  Dockerfile_ubuntu_compile  main.py    rm_containers.sh          tmpfs
build_rootfs2.sh     finish_containers.sh       qemu2.sh   rootfs_debian_amd64.ext4  ubuntu24-base.ext4
```
## Run your os
Congratulations, you can finally use start_qemu.sh to run your os now.
```
sudo bash start_qemu.sh --kernel=/home/dylane/code/linux-next/arch/x86_64/boot/bzImage --rootfs=rootfs_debian_amd64.ext4
```
system starting...
```
[  OK  ] Started serial-getty@ttyS0.service - Serial Getty on ttyS0.
Starting setvtrgb.service - Set console scheme...
[  OK  ] Started dbus.service - D-Bus System Message Bus.
[  OK  ] Finished setvtrgb.service - Set console scheme.
[  OK  ] Created slice system-getty.slice - Slice /system/getty.
[  OK  ] Started getty@tty1.service - Getty on tty1.
[  OK  ] Reached target getty.target - Login Prompts.
[  OK  ] Started systemd-logind.service - User Login Management.
[  OK  ] Started rsyslog.service - System Logging Service.
[  OK  ] Finished e2scrub_reap.service - Re…line ext4 Metadata Check Snapshots.
[  OK  ] Reached target multi-user.target - Multi-User System.
[  OK  ] Reached target graphical.target - Graphical Interface.
Starting systemd-update-utmp-runle…- Record Runlevel Change in UTMP...
[  OK  ] Finished systemd-update-utmp-runle…e - Record Runlevel Change in UTMP.

Ubuntu 24.04 LTS debian ttyS0

debian login:
```
Debugging your ebpf tools from kernel to application
```
root@debian:/boot# ./cpudist
Tracing on-CPU time... Hit Ctrl-C to end.
^C
     usecs               : count    distribution
         0 -> 1          : 0        |                                        |
         2 -> 3          : 0        |                                        |
         4 -> 7          : 0        |                                        |
         8 -> 15         : 0        |                                        |
        16 -> 31         : 0        |                                        |
        32 -> 63         : 0        |                                        |
        64 -> 127        : 1        |********                                |
       128 -> 255        : 1        |********                                |
       256 -> 511        : 1        |********                                |
```
**The specific usage of all scripts can be viewed through the help command**
# Acknowledgements
This project makes use of the following open source projects:
- [kernel-build-containers](https://github.com/a13xp0p0v/kernel-build-containers) under the Apache License 3.0

