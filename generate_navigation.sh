#!/bin/bash

#remove current list of plugins
< ./hop-user-manual/modules/ROOT/nav.adoc sed '/::=START/,/::=END/{/::=START/!{/::=END/!d}}' > ./hop-user-manual/modules/ROOT/nav_temp.adoc

#replace nav with empty
cp ./hop-user-manual/modules/ROOT/nav_temp.adoc ./hop-user-manual/modules/ROOT/nav.adoc

#move to plugins directory
cd ./hop-user-manual/modules/ROOT/pages/plugins/


#loop over adoc files
FILE_LIST=""
for f in $(find . -type f -name '*.adoc' ! -name 'plugins.adoc' -exec bash -c 'echo -n '{}':; echo '{}' | grep -o / | wc -l | sort' \; | LC_ALL=C sort -r)
do
	#get details
	NESTING_LEVEL=$(($(awk -F  ":" '{print $2}' <<< $f)+1));
	FILE_LOCATION=$(awk -F  ":" '{print $1}' <<< $f | cut -c3-)
	FILE_PATH=$(echo "$FILE_LOCATION" | cut -f1 -d/)
	FILE_NAME=$(grep -m 1 -nr "=" $(awk -F  ":" '{print $1}' <<< $f) | awk -F  "=" '{print $2}' | sed -e 's/^[[:space:]]*//');
	NESTING_STARS=$(printf '*%.0s' $(seq $NESTING_LEVEL))
	FILE_LIST="${FILE_LIST}/$FILE_LOCATION;$FILE_NAME;$NESTING_STARS;$FILE_PATH\n"
done
echo -e "$FILE_LIST" | head -c -1 > /tmp/nav-unsorted 

#read sorted file
while read -r line
do
	#get sorted details
	FILE_LOCATION=$(echo "$line" | cut -f1 -d\;)
	FILE_NAME=$(echo "$line" | cut -f2 -d\;)
	NESTING_STARS=$(echo "$line" | cut -f3 -d\;)
		
	#create xref
	NEW_LINE="$NESTING_STARS xref:plugins$FILE_LOCATION[$FILE_NAME]"
	
	#add xref to file
	awk "/::=START/ { print; print \"$(echo "$NEW_LINE")\"; next }1" ../../nav.adoc > ../../nav_temp.adoc
	cp ../../nav_temp.adoc ../../nav.adoc
	echo """$NEW_LINE"""
done < <(sort --field-separator=';' -k4,4 -k2,2r /tmp/nav-unsorted)

#remove temp
rm /tmp/nav-unsorted
rm ../../nav_temp.adoc

#go back to root
cd ../../../../..


#generate asciidoc index based on antora naviagtion file

#remove current list
< ./hop-user-manual/modules/.asciidoctor/pages/index.adoc sed '/::=START/,/::=END/{/::=START/!{/::=END/!d}}' > ./hop-user-manual/modules/.asciidoctor/pages/index_temp.adoc

#replace nav with empty
cp ./hop-user-manual/modules/.asciidoctor/pages/index_temp.adoc ./hop-user-manual/modules/.asciidoctor/pages/index.adoc

#reverse file order
tac ./hop-user-manual/modules/ROOT/nav.adoc > /tmp/nav_reversed.adoc

#read nav.adoc

while read p; do
	#count * in line
  	echo "Line: $p"
	NESTING_LEVEL=$(echo "$p" | tr -d -c '*' | awk '{ print length; }')
	NESTING_LEVEL=$(($NESTING_LEVEL-1))
	echo "Nesting Level: $NESTING_LEVEL"

	if (($NESTING_LEVEL >= 0)) 
	then
		# if [ $NESTING_LEVEL -eq 0 ]
		# then
			# NEW_LINE="include::{sourcepath}/$(grep -oP '(?<=\:).*?(?=\[)' <<< "$p")"
		# else
			NEW_LINE="include::{sourcepath}/$(grep -oP '(?<=\:).*?(?=\[)' <<< "$p")[leveloffset=+$NESTING_LEVEL]"
		# fi
	
	echo "File Path: $NEW_LINE"
	awk "/::=START/ { print; print \"$(echo "$NEW_LINE")\"; next }1" ./hop-user-manual/modules/.asciidoctor/pages/index.adoc > ./hop-user-manual/modules/.asciidoctor/pages/index_temp.adoc
	cp ./hop-user-manual/modules/.asciidoctor/pages/index_temp.adoc ./hop-user-manual/modules/.asciidoctor/pages/index.adoc
	
	fi


done < /tmp/nav_reversed.adoc

#cleanup
rm /tmp/nav_reversed.adoc
rm ./hop-user-manual/modules/.asciidoctor/pages/index_temp.adoc


