#!/usr/bin/env sh

# Prepare Latvian List
#
clear
# Prepare Firefox list
perl tools/sorter.pl lists/latvian-list.txt
perl tools/addChecksum.pl lists/latvian-list.txt
#
echo -n "Press enter to proceed:"
read xx