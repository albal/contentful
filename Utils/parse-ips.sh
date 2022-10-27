#!/bin/bash
filein="raw-ips.txt"
fileout="ips.txt"
count=1
start=500
grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}|([0-9]{1,3}[\.]){3}[0-9]{1,3}/[0-9]{1,2}' $filein | uniq > $fileout
