#!/usr/bin/env bash

unique_strings () {
    if [ "$1" ]
    then
        FILES="$1"
    else
        FILES="*.lproj/Localizable.strings"
    fi

    cat $FILES | \
    awk -F= '{ print $1 }' | \
    grep -Ev '^[^"].*[^"]$' | \
    sed 's/[ ]*$//g' | \
    sort | \
    uniq
}

unique_strings > all_strings

for i in `ls *.lproj/Localizable.strings | grep -v en.lproj`; do
    unique_strings $i > current;
    UNTRANSLATED_STRINGS=`comm -23 all_strings current | grep -v "^$" | sed 's/\(.*\)$/\1 = \1;/g'`
    if [[ ! -z $UNTRANSLATED_STRINGS ]]; then
        echo "" >> $i
        echo "" >> $i
        echo "/*" >> $i
        echo "// Untranslated Strings" >> $i
        echo "" >> $i
        echo "$UNTRANSLATED_STRINGS" >> $i
        printf "\n*/" >> $i
    fi
done;

rm current
rm all_strings
