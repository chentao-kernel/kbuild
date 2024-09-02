#!/bin/bash

source_code="/home/dylane/code/linux-next/"

if [ -n "$1" ]; then
        source_code=$1
fi

mkdir -p ~/.config/gdb

touch ~/.config/gdb/gdbinit

echo 'add-auto-load-safe-path /home/dylane/code/linux-next/scripts/gdb/vmlinux-gdb.py' >> ~/.config/gdb/gdbinit
echo 'set auto-load safe-path /' >> ~/.config/gdb/gdbinit

echo "config gdb init success"
