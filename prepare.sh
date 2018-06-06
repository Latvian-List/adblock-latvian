#!/usr/bin/env sh

# Prepare Latvian List

# Prepare Firefox list
perl tools/sorter.pl lists/latvian-list.txt
perl tools/addChecksum.pl lists/latvian-list.txt
