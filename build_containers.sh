#!/bin/bash

groups | grep docker
NEED_SUDO=$?

if [ $NEED_SUDO -eq 1 ]; then
	echo "Hey, we gonna use sudo for running docker"
	SUDO_CMD="sudo"
else
	echo "Hey, you are in docker group, sudo is not needed"
	SUDO_CMD=""
fi

set -e

CLANG_VERSION=""
GCC_VERSION=""
UBUNTU_VERSION=""

function print_help() {
	echo "usage: $0 gcc_version/clang_version ubuntu_version"
	echo "  -g    set gcc version"
	echo "  -c    set clang version"
	echo "  -u    set ubuntu versoin"
	echo "  -h    print this help"
	echo ""
	echo "	gcc: 4.9, ubuntu: 16.04"
	echo "	gcc: 5, ubuntu: 16.04"
	echo "	gcc: 6, ubuntu: 18.04"
	echo "	gcc: 7, ubuntu: 20.04"
	echo "	gcc: 8, ubuntu: 20.04"
	echo "	gcc: 9, ubuntu: 20.04"
	echo "	gcc: 10, ubuntu: 20.04"
	echo "	gcc: 11, ubuntu: 22.04"
	echo "	gcc: 12, ubuntu: 22.04"
	echo "	gcc: 13, ubuntu: 23.04"
	echo "	gcc: 14, ubuntu: 24.04"
}

function build_gcc_container() {
	echo -e "\nBuilding a container with GCC_VERSION=$1 from UBUNTU_VERSION=$2"
	$SUDO_CMD docker build \
		--file Dockerfile_ubuntu_compile \
		--build-arg GCC_VERSION=$1 \
		--build-arg UBUNTU_VERSION=$2 \
		--build-arg UNAME=$(id -nu) \
		--build-arg UID=$(id -u) \
		--build-arg GID=$(id -g) \
		-t kernel-build-container:gcc-${GCC_VERSION} .
}

function build_all_gcc_containers() {
	GCC_VERSION="4.9"
	UBUNTU_VERSION="16.04"
	build_gcc_container ${GCC_VERSION} ${UBUNTU_VERSION}

	GCC_VERSION="5"
	UBUNTU_VERSION="16.04"
	build_gcc_container ${GCC_VERSION} ${UBUNTU_VERSION}

	GCC_VERSION="6"
	UBUNTU_VERSION="18.04"
	build_gcc_container ${GCC_VERSION} ${UBUNTU_VERSION}

	GCC_VERSION="7"
	UBUNTU_VERSION="18.04"
	build_gcc_container ${GCC_VERSION} ${UBUNTU_VERSION}

	GCC_VERSION="8"
	UBUNTU_VERSION="20.04"
	build_gcc_container ${GCC_VERSION} ${UBUNTU_VERSION}

	GCC_VERSION="9"
	UBUNTU_VERSION="20.04"
	build_gcc_container ${GCC_VERSION} ${UBUNTU_VERSION}

	GCC_VERSION="10"
	UBUNTU_VERSION="20.04"
	build_gcc_container ${GCC_VERSION} ${UBUNTU_VERSION}

	GCC_VERSION="11"
	UBUNTU_VERSION="22.04"
	build_gcc_container ${GCC_VERSION} ${UBUNTU_VERSION}

	GCC_VERSION="12"
	UBUNTU_VERSION="22.04"
	build_gcc_container ${GCC_VERSION} ${UBUNTU_VERSION}

	GCC_VERSION="13"
	UBUNTU_VERSION="23.04"
	build_gcc_container ${GCC_VERSION} ${UBUNTU_VERSION}

	GCC_VERSION="14"
	UBUNTU_VERSION="24.04"
	build_gcc_container ${GCC_VERSION} ${UBUNTU_VERSION}
}

build_clang_container() {
	echo -e "\nBuilding a container with CLANG_VERSION=$1 and GCC_VERSION=$2 from UBUNTU_VERSION=$3"
	$SUDO_CMD docker build \
		--file Dockerfile_ubuntu_compile \
		--build-arg CLANG_VERSION=$1 \
		--build-arg GCC_VERSION=$2 \
		--build-arg UBUNTU_VERSION=$3 \
		--build-arg UNAME=$(id -nu) \
		--build-arg UID=$(id -u) \
		--build-arg GID=$(id -g) \
		-t kernel-build-container:clang-${CLANG_VERSION} .
}

function build_all_clang_containers() {
	CLANG_VERSION="12"
	GCC_VERSION="11"
	UBUNTU_VERSION="22.04"
	build_clang_container ${CLANG_VERSION} ${GCC_VERSION} ${UBUNTU_VERSION}

	CLANG_VERSION="13"
	GCC_VERSION="11"
	UBUNTU_VERSION="22.04"
	build_clang_container ${CLANG_VERSION} ${GCC_VERSION} ${UBUNTU_VERSION}

	CLANG_VERSION="14"
	GCC_VERSION="12"
	UBUNTU_VERSION="22.04"
	build_clang_container ${CLANG_VERSION} ${GCC_VERSION} ${UBUNTU_VERSION}

	CLANG_VERSION="15"
	GCC_VERSION="12"
	UBUNTU_VERSION="22.04"
	build_clang_container ${CLANG_VERSION} ${GCC_VERSION} ${UBUNTU_VERSION}
}


function main() {
	while [[ $# -gt 0 ]]; do
	case $1 in
		-c | --clang_version)
			CLANG_VERSION="$2"
			shift 2
			;;
		-u | --ubuntu_version)
			UBUNTU_VERSION="$2"
			shift 2
			;;
		-g | --gcc_version)
			GCC_VERSION="$2"
			shift 2
			;;
		-h | --help)
			print_help
			exit 0
			;;
		*)
			echo "Unknown option $1"
			print_help
			exit 1
			;;
	esac
	done
	echo "GCC VERSION:$GCC_VERSION,CLANG VERSION:$CLANG_VERSION,UBUNTU VERSION:$UBUNTU_VERSION"
	if [ -z "$CLANG_VERSION" ];then
		build_gcc_container ${GCC_VERSION} ${UBUNTU_VERSION}
	else
		build_clang_container ${CLANG_VERSION} ${GCC_VERSION} ${UBUNTU_VERSION}
	fi
}

main $@
