#!/bin/bash

subdircount=$(find . -maxdepth 1 -type d | wc -l)

if [[ "$subdircount" -eq 1 ]]
then
	exit
else
	for dir in */; do
	        dirname=$(basename $dir)
	        zipname="$dirname".tar.gz
		tar czf "$zipname" "$dir"
		gpg --batch --yes -se -r $USERNAME "$zipname"
		if [ -f "$zipname".gpg ] ; then
			rm -rf "$dir"
			rm "$zipname"
		fi
	done
fi

