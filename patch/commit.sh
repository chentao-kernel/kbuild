#!/bin/bash
# Copyright: Copyright (c) Tao Chen
# Author: Tao Chen <chen.dylane@gmail.com>
# Time: 2024-11-14 00:12:36
#
program="$0"

function print_help() {
	echo "usage: $0 find merged version by commit title"
	echo
	echo "Examples:"
	echo
	echo "${program} -m "sched_ext: Add boilerplate for extensible scheduler class""
	echo
}

function main() {
	while [ $# -gt 0 ]; do
	case $1 in
		-m | --commit)
			find_ver_with_commit $2
			;;
		-h | --help)
			print_help
			exit 0
			;;
	esac
	done
}

function find_ver_with_commit() {
	if [ -z "$1" ]; then
	echo "please input a commit title。"
	exit 1
	fi

	COMMIT_TITLE=$1

	COMMIT_HASH=$(git log --oneline --grep="$COMMIT_TITLE" | head -n 1 | awk '{print $1}')

	if [ -z "$COMMIT_HASH" ]; then
	echo "Unable to find matching commit：$COMMIT_TITLE"
	exit 1
	fi

	echo "found commit hash: $COMMIT_HASH"

	VERSION=$(git describe --tags "$COMMIT_HASH")

	if [ $? -eq 0 ]; then
	echo "The commit merged version is: $VERSION"
	else
	echo "This commit: $VERSION not found in any versions "
	fi
}

main $@
