#!/bin/bash
#==VAR==========================================================================
OLD_FILE=$2
NEW_FILE=$5
TMP_RANDOM=$(pwgen 50 1)
COMPARE_TMP_FILE=/tmp/graphixdiff.$TMP_RANDOM
XCF_2_PNG_TMP_OLD_FILE=/tmp/graphixdiff.$TMP_RANDOM.old.png
XCF_2_PNG_TMP_NEW_FILE=/tmp/graphixdiff.$TMP_RANDOM.new.png
HEXDUMP_TMP_OLD_FILE=/tmp/graphixdiff.$TMP_RANDOM.old.hex
HEXDUMP_TMP_NEW_FILE=/tmp/graphixdiff.$TMP_RANDOM.new.hex

#==FUNCTIONS====================================================================
function compareimage {
    compare "$1" "$2" "$COMPARE_TMP_FILE"
    eog  "$COMPARE_TMP_FILE"
    rm "$COMPARE_TMP_FILE"
}

function comparexcf {
    xcf2png "$1" -o "$XCF_2_PNG_TMP_OLD_FILE"
    xcf2png "$2" -o "$XCF_2_PNG_TMP_NEW_FILE"
    compareimage "$XCF_2_PNG_TMP_OLD_FILE" "$XCF_2_PNG_TMP_NEW_FILE"
    rm "$XCF_2_PNG_TMP_OLD_FILE" "$XCF_2_PNG_TMP_NEW_FILE"
}

function binarydiff {
    hexdump "$1" > "$HEXDUMP_TMP_OLD_FILE"
    hexdump "$2" > "$HEXDUMP_TMP_NEW_FILE"
    meld "$HEXDUMP_TMP_OLD_FILE" "$HEXDUMP_TMP_NEW_FILE"
    rm "$HEXDUMP_TMP_OLD_FILE" "$HEXDUMP_TMP_NEW_FILE"
}

#==MAIN=========================================================================
#Make sure the tempfile does not exist
for i in "$COMPARE_TMP_FILE" "$XCF_2_PNG_TMP_OLD_FILE" \
         "$XCF_2_PNG_TMP_NEW_FILE" "$HEXDUMP_TMP_OLD_FILE" \
         "$HEXDUMP_TMP_NEW_FILE"; do
    if [ -f "$i" ]; then
        echo "FATAL ERROR: tmp file $i already exists"
        exit 1
    fi
done

#Use meld for any kind of ASCII files, compare for images and hexdump with meld 
#for unsupported filetypes
#FIXME: find a better solution to determine if a file is ASCII or binary.
#FIXME: Shell scripts are currently not detected as ASCII

if [ -n "$(file $OLD_FILE | grep  ASCII)" -a \
     -n "$(file $NEW_FILE | grep  ASCII)" ] ; then
    echo "ASCII detected calling meld..."
    meld $OLD_FILE $NEW_FILE
else
    case "${NEW_FILE##*.}" in
        gif | png | jpg | jpeg | tiff) 
            echo "Image detected calling compare..."
            compareimage "$OLD_FILE" "$NEW_FILE"
            ;;
        xcf)
            echo "Gimp xcf detected calling compare..."
            comparexcf "$OLD_FILE" "$NEW_FILE"
            ;;
        *)
            echo "Filetype not supported fall back to meld with hexdumps..."
            binarydiff "$OLD_FILE" "$NEW_FILE"
            ;;
    esac
fi

exit 0
