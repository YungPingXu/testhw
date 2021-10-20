#!/bin/sh

#datediff(){
#   d1=$(date -d "$1" +%s)
#   d2=$(date -d "$2" +%s)
#   echo $(( (d1 - d2) / 86400 ))
#}

#datediff now "$date"
date -j -f "%b %d %T" "Oct 20 11:36:00" "+%s"
date "+%s"