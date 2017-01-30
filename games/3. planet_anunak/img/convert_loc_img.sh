#!/usr/bin/zsh

cd ~/prog/INSTEAD/planet_anunak/img/locations

for file in `find . -name "№*.png"`
do
	mogrify -resize 341x220! "$file"
	mv $file "${file/№/p}"
done
