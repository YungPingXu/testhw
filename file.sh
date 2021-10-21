#!/bin/sh


input="~/asd.txt"
tmp=$(echo $input | cut -c1)
if [ $tmp = "~" ] ; then
	replace=$(echo "$input" | sed "s/^.\(.*\)/\1/")
	path=$(echo $HOME $replace)
else
	path=$input
fi

echo $path

echo "content > $path