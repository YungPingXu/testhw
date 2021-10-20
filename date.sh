#!/bin/sh

#datediff(){
#   d1=$(date -d "$1" +%s)
#   d2=$(date -d "$2" +%s)
#   echo $(( (d1 - d2) / 86400 ))
#}

#datediff now "$date"
date -j -f "%a %b %d %T %Y" "Wed Apr 22 17:43:30 2021" "+%s"