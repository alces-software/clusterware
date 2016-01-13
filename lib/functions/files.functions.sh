#==============================================================================
# Copyright (C) 2015 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Clusterware.
#
# Alces Clusterware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Clusterware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Clusterware, please visit:
# https://github.com/alces-software/clusterware
#==============================================================================
# An array of temporary files to clean up when this process cleans up.
declare TEMPFILES
# An array of temporary directories to clean up when this process cleans up.
declare TEMPDIRS

files_mktempdir() {
    local dir
    dir="$1"
    mkdir -p "${dir}"
    files_mark_tempdir "${dir}"
}

files_mark_tempdir() {
    TEMPDIRS+=("$1")
}

files_mark_tempfile() {
    TEMPFILES+=("$1")
}

files_cleanup() {
    local file dir tmr tmout
    tmout="${1:-5}"
    for file in "${TEMPFILES[@]}" ; do
        if [ -z "$cw_DEBUG" ]; then
            rm "${file}" 2>/dev/null
        else
            action_debug "rm $file"
        fi
    done
    for dir in "${TEMPDIRS[@]}" ; do
        if [ -z "$cw_DEBUG" ]; then
            tmr=0
            while [ $tmr -lt $tmout ] && ! rmdir "${dir}" 2>/dev/null; do
                # Wait a second in case file handles are still being cleaned up
                tmr=$(($tmr+1))
                sleep 1
            done
        else
            action_debug "rmdir $dir"
        fi
    done
}

files_wait_for_file() {
    local file tmout tmr
    file="$1"
    tmout="$2"
    tmr=0
    while true; do
        if [ -f "$file" ]; then
            break
        elif [ "$tmout" -a $tmr -lt $tmout ]; then
            tmr=$(($tmr+1))
            sleep 1
        else
            return 1
        fi
    done
}

files_load_config() {
    local base name optional path
    if [ "$1" == "--optional" ]; then
        optional=true
        shift
    fi
    name=$1
    base=$2

    if [ "$base" ]; then
        path="${cw_ROOT}/etc/${base}"
    else
        path="${cw_ROOT}/etc"
    fi

    if [ -r "${path}/${name}.vars.sh" ]; then
        . "${path}/${name}.vars.sh"
    elif [ -r "${path}/${name}.rc" ]; then
        . "${path}/${name}.rc"
    else
        if [ "$optional" ]; then
            return 1
        else
            echo "FATAL: unable to locate ${name} configuration in given path: ${path}"
            exit 1
        fi
    fi
}
