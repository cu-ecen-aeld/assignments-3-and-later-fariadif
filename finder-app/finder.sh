#!/bin/bash

filesdir=$1
searchstr=$2

if [ ! $# -eq 2 ]; then
	echo "params not set"
	exit 1
fi

if [ ! -d "$filesdir" ]; then
	echo "filesdir is not a directory"
	exit 1
fi

y=$(grep -Ir $searchstr $filesdir | wc -l)
x=$(grep -Ir $searchstr $filesdir -l | wc -l)

echo "The number of files are $x and the number of matching lines are $y"
