#!/bin/sh

cat /var/log/auth.log | grep -E "sudo|COMMAND=" | \
awk -F" : |;" '{for(i=1;i<NF;i++) printf $i ";"; print $NF;}' | \
awk -F";" '{print $1 " " $NF;}' | \
awk -F"COMMAND=" '{print $1 " " $2}' | \
awk '{if($6=='$username'){ \
    printf $6 " used sudo to do `"; \
    for(i=7;i<NF;i++) printf $i " "; \
    print $NF "` on " $1 " " $2 " " $3
}}'