#!/bin/sh

# Prepare Latvian List
#
clear
# Prepare Firefox list
perl tools/sorter.pl lists/latvian-list.txt
perl tools/addChecksum.pl lists/latvian-list.txt
#
# Prepare Opera list
perl tools/createOperaFilters.pl lists/latvian-list.txt --nocss
perl tools/addChecksum_Opera.pl lists/urlfilter.ini
perl tools/addChecksum.pl lists/element-filter.css
#
echo -n "Press enter to proceed:"
read xx