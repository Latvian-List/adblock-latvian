:: Prepare Latvian List
::
@cls
:: Prepare Firefox list
perl tools\sorter.pl lists\latvian-list.txt
perl tools\addChecksum.pl lists\latvian-list.txt
::
:: Prepare Opera list
perl tools\createOperaFilters.pl lists\latvian-list.txt --addcustomcss lists\specific_elements.css
perl tools\addChecksum_Opera.pl lists\urlfilter.ini
perl tools\addChecksum.pl lists\element-filter.css
::
pause