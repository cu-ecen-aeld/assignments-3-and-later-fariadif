#!/bin/bash

if [ ! $# -eq 2 ]; then
	echo "arguments no set"
	exit 1
fi

writefile=$1
writestr=$2

mkdir -p $(dirname $writefile)

if [ $(echo "$writestr" > $writefile) ]; then
	echo "cannot create file"
	exit 1
fi
