:: Prepare Latvian List
::
:: Prepare Firefox list
perl sorter.pl ..\latvian-list.txt
perl addChecksum.pl ..\latvian-list.txt
::
:: Prepare Opera list
::perl automagically_create_opera_filters.pl ..\latvian-list.txt
perl addChecksum_Opera.pl ..\urlfilter.ini
perl addChecksum.pl ..\element-filter.css
::
:: Prepare IE TPL
perl createTPL.pl ..\latvian-list.txt
pause