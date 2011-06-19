#!/bin/sh

# Prepare Latvian List
#
clear
# Prepare Firefox list
perl sorter.pl ../latvian-list.txt
perl addChecksum.pl ../latvian-list.txt
#
# Prepare Opera list
perl createOperaFilters.pl ../latvian-list.txt -nocss
perl addChecksum_alt.pl ../urlfilter.ini
perl addChecksum.pl ../element-filter.css
#
# Prepare IE list
perl createIETPL.pl ../latvian-list.txt
perl addChecksum_alt.pl ../latvian-list.tpl
#
echo -n "Press enter to proceed:"
read xx