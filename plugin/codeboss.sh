#!/bin/bash

# Copyright: Copyright (C) 2018 Andrey Shvetsov
# License: The MIT License
#
# This script is the part of the vim-codeboss plugin - cscope helper for vim.

# TODO: Add support of spaces and double-quotes in filenames.
#
# See also cscope man:
#
# Filenames in the namefile that contain whitespace have to be enclosed in
# "double quotes".  Inside such quoted filenames, any double-quote and
# backslash characters have to be escaped by backslashes.
#
# Hint: sed -r -e "s,([\"\\]),\\\\\1,g" -e "s,^,\"," -e "s,$,\","
#

_list_files() {
    local obj="$1"
    if [ -d "$obj" ]; then
        find "$obj"/* -type f
    else
        find "$obj" -type f
    fi
}

_add_if_new() {
    local n="$1"
    [ -e .cboss.files ] && grep -m 1 -q "^${n}$" .cboss.files && return
    [ -e cscope.files ] && grep -m 1 -q "^${n}$" cscope.files && return
    echo "$n" >>.cboss.files
    echo .  # used by [ -n "..." ] in add()
}

# Adds the name of an existing c/cpp file into the cscope namefile .cboss.files
# unless it is already there or in the namefile cscope.files
#
# If the 1st parameter is the directory name then adds all files from this
# directory and their subdirectories according to the rules above.
#
# Returns with the status 0 iif at least one file is added.
#
add() {
    [ -n "$(_list_files "$(readlink -f "$1")" |
        egrep -i "\.[ch](|pp|\+\+)$|\.cc$" |
            while read n; do _add_if_new "$n"; done |
                uniq)" ]
}

# Checks if the file is tracked by the .cboss.files
#
# Returns with the status 0 iif file is tracked.
#
is_tracked() {
    [ -e .cboss.files ] &&
        grep -m 1 -q "^$(readlink -f "$1")$" .cboss.files
}

# Rebuilds the cross-references for the files in the .cboss.files
#
rebuild() {
    [ -e .cboss.files ] &&
        cscope -v -R -b -q -k -i .cboss.files -f .cboss.out ||
        rm -f .cboss.out*
}

"$@"

# vim: ts=4 sw=4 et ft=sh
