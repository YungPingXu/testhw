echo "DATE IP"
last "yungping" | \
grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
awk '{print $4 " " $5 " " $6 " " $7 " " $3}'