#!/bin/bash

for dir in *.tar.gz.gpg; do
	filename=$(basename -- "$dir")
	filename="${filename%.tar.gz.gpg}"
	gpg -d -o "$filename".tar.gz "$dir"
	tar -xf "$filename".tar.gz
done
