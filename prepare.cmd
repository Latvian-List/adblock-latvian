:: Prepare Latvian List
::
@cls
:: Prepare Firefox list
perl tools\sorter.pl lists\latvian-list.txt
perl tools\addChecksum.pl lists\latvian-list.txt
::
:: Prepare Opera list
perl tools\createOperaFilters.pl lists\latvian-list.txt --nocss
perl tools\addChecksum_alt.pl lists\urlfilter.ini
perl tools\addChecksum.pl lists\element-filter.css
::
:: Prepare IE list
perl tools\createIETPL.pl lists\latvian-list.txt
perl tools\addChecksum_alt.pl lists\latvian-list.tpl
::
pause