#!/bin/bash

SRC=$1

make headers

make -C ${SRC}/tools/testing/selftests/bpf -j "$(nproc)"
