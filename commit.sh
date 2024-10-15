#!/bin/bash

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
