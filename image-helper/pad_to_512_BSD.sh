#!/bin/sh

if [ ! -f "$1" ]; then
	echo Usage: $0 filename
	return 1
fi

BLOCKSIZE=512

FILENAME=$1
FILESIZE=$(stat -f "%z" $FILENAME)

PADDING=$((($BLOCKSIZE - ($FILESIZE % $BLOCKSIZE)) % $BLOCKSIZE))

echo Padding with $PADDING bytes


dd if=/dev/zero conv=notrunc bs=1 count=$PADDING seek=$FILESIZE of=$FILENAME
