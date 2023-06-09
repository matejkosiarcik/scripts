#!/bin/sh
set -euf

usage() {
    printf 'Usage: exifdir [-h] [-n] [-i] [-f] <dir>\n'
    printf ' dir    directory to analyze\n'
    printf ' -h     show help message\n'
    printf ' -n     dry run\n'
    printf ' -f     force\n'
}

if [ "$#" -lt 2 ]; then
    printf 'Not enough arguments\n\n' >&2
    usage >&2
    exit 1
fi

mode=''
if [ "$1" = '-n' ]; then
    mode='n'
elif [ "$1" = '-f' ]; then
    mode='f'
fi
if [ "$mode" = '' ]; then
    printf 'No mode specified (specify either -n|-i|-f)\n\n' >&2
    usage >&2
    exit 1
fi

dir="$2"
cd "$dir"

find . \( \
    -iname '*.3gp' -or \
    -iname '*.avi' -or \
    -iname '*.jpeg' -or \
    -iname '*.jpg' -or \
    -iname '*.m4a' -or \
    -iname '*.m4v' -or \
    -iname '*.mov' -or \
    -iname '*.mp4' -or \
    -iname '*.wav' \
    \) -type f | sort --version-sort | while read -r file; do
    filedir="$dir/$(dirname "$file")"
    filename="$(basename "$file")"
    fileext="$(printf '%s' "$filename" | sed -E 's~^.*\.~~')"

    # Get photo creation date
    date="$(exiftool -short -short -short -CreateDate "$file" 2>/dev/null | sed 's~:~-~g;s~\.~-~g;s~ ~_~g')"
    if [ "$date" = '' ] || [ "$date" = '0000-00-00_00-00-00' ] || [ "$date" = '0000-00-00' ]; then
        date="$(exiftool -short -short -short -DateTimeOriginal "$file" 2>/dev/null | sed 's~:~-~g;s~\.~-~g;s~ ~_~g')"
    fi
    if [ "$date" = '' ] || [ "$date" = '0000-00-00_00-00-00' ] || [ "$date" = '0000-00-00' ]; then
        # "-FileModifyDate" is often not reliable, but better than nothing if the previous methods yield nothing
        date="$(exiftool -short -short -short -FileModifyDate "$file" 2>/dev/null | sed 's~:~-~g;s~\.~-~g;s~ ~_~g' | sed -E 's~\+.+$~~')"
    fi
    if [ "$date" = '0000-00-00_00-00-00' ] || [ "$date" = '0000-00-00' ]; then
        # unset date when it is bogus
        date=''
    fi

    if [ "$date" != '' ]; then
        printf '%s: %s\n' "$date" "$filename" >&2
        if [ "$mode" = 'f' ]; then
            newfilename="$date.$fileext"

            # Check if the new file already exists (2 photos with the exact date taken)
            # In such case name the second photo with an iterator suffix
            i=0
            while [ -e "$filedir/$newfilename" ]; do
                i="$((i + 1))"
                newfilename="$date $i.$fileext"
            done

            mv "$filedir/$filename" "$filedir/$newfilename"
        fi
    else
        printf 'ERROR: No date for %s\n' "$filename" >&2
    fi
done

# If there were some collisions (multiple photos with the same exact date)
# The first photo will lack suffix (as a consequence, it will be sorted last in programs such as file explorer)
# So add 0 suffix to it
if [ "$mode" = 'f' ]; then
    find . \( \
        -iname '*.3gp' -or \
        -iname '*.avi' -or \
        -iname '*.jpeg' -or \
        -iname '*.jpg' -or \
        -iname '*.m4a' -or \
        -iname '*.m4v' -or \
        -iname '*.mov' -or \
        -iname '*.mp4' -or \
        -iname '*.wav' \
        \) -and -name "* 1.*" -type f | sort --version-sort | while read -r file; do
        filename="$(basename "$file")"
        fileext="$(printf '%s' "$filename" | sed -E 's~^.*\.~~')"
        filedate="$(basename "$file" " 1.$fileext")"
        oldfile="$(dirname "$file")/$filename"
        newfile="$(dirname "$file")/$filedate 0.$fileext"
        if [ ! -e "$newfile" ]; then
            mv "$oldfile" "$newfile"
        else
            printf '%s already exist!\n' "$newfile" >&2
        fi
    done
fi
