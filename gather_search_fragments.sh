#!/bin/bash

my_dir="$(dirname "$(realpath "$0")")"

disclaimer="/* Do not touch! Auto-generated by $(basename $0)*/"

get_xml_root_string() {
    file="$1"
    attr="$2"
    output="$(echo -e setns android=http://schemas.android.com/apk/res/android \\n cat /PreferenceScreen/@$attr | xmllint "$file" --shell)"
    content="$(echo "$output" | grep "$attr=")"
    if [ $? = 0 ]; then
        echo "$content" | sed "s/.*$attr=//" | sed 's/"//g'
    fi
}

string_ref_xml_to_java() {
    echo "$1" | sed 's|@string/|R.string.|'
}

components=""

for fragment in "$my_dir/src/com/aicp/extras/fragments/"*; do
    fragment_short="$(basename "$fragment" .java)"
    fragment_full="com.aicp.extras.fragments.$fragment_short"

    # Get xml resource
    xmlres="$(grep -A1 getPreferenceResource "$fragment" | grep return | sed 's/.* //' | sed 's/;//')"
    if echo "$xmlres" | grep -q "R.xml."; then
        xmlfile="$my_dir/res/xml/$(echo "$xmlres" | sed 's/R.xml.//').xml"
        #cat "$fragment" | tr '\n' '\r' | sed 's/getPreferenceResource()
        title="$(get_xml_root_string $xmlfile android:title)"
        summary="$(get_xml_root_string $xmlfile android:summary)"
        if [ -z "$title" ]; then
            >&2 echo "Could not find title in $xmlfile"
        else
            key="$(get_xml_root_string $xmlfile android:key)"
            title="$(string_ref_xml_to_java "$title")"
            if [ -z "$summary" ]; then
                summary=0
            else
                summary="$(string_ref_xml_to_java "$summary")"
            fi
            echo "Adding $fragment_short to searchables"
            components="$components\n        new AeFragmentInfo(\"$fragment_full\", \"$key\", $title, $summary, $xmlres),"
        fi
    else
        >&2 echo "Could not find xml resource for $fragment_full"
    fi
done

cat "$my_dir/AeFragmentList.java" | sed "s|/\\* xx0xx \\*/|$disclaimer|" | sed "s|/\\* xx1xx \\*/|$components|" > "$my_dir/src/com/aicp/extras/search/AeFragmentList.java"
