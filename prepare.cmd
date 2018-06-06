:: Prepare Latvian List
::
@cls
:: Prepare Firefox list
perl tools\sorter.pl lists\latvian-list.txt
perl tools\addChecksum.pl lists\latvian-list.txt
::
pause
