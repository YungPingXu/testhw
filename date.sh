#!/bin/sh

#datediff(){
#   d1=$(date -d "$1" +%s)
#   d2=$(date -d "$2" +%s)
#   echo $(( (d1 - d2) / 86400 ))
#}

#datediff now "$date"
datediff(){
   d1=$(date)
   d2=$(date -j -v-30d)
   echo $(( (d1 - d2) / 86400 ))
}
datediff