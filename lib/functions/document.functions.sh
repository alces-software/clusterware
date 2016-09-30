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
require ruby

cw_DOCUMENT_dir="${cw_ROOT}/var/lib/docs/base"

document_show() {
    local roff doc psdoc ronn man_opts
    doc="$1"
    manual="${2:-Alces Clusterware}"
    ronn=( \
        ronn --pipe \
        --organization="Alces Software Ltd" \
        --manual="${manual}" \
        -r "${doc}" )
    roff="$(ruby_bundle_exec "${ronn[@]}")"
    if [ "$DISPLAY" ] && type -p evince > /dev/null; then
        psdoc="$(mktemp /tmp/$(basename "${doc}").XXXXXX.ps)"
        man -t /dev/stdin <<< "${roff}" > "${psdoc}"
        (
            evince "${psdoc}" &>/dev/null
            rm -f "${psdoc}"
        ) &
    else
        if [ -z "$MANPAGER" ]; then
            man_opts=(-P "less -F")
        fi
        man "${man_opts[@]}" /dev/stdin <<< "${roff}"
    fi
}

document_list() {
    local type glob docs docdirs dir
    type="$1"
    glob="*${2}"
    docs=()
    IFS=: read -a docdirs <<< "${cw_DOCUMENT_dir}:${CW_DOCPATH}"
    for dir in "${docdirs[@]}"; do
        shopt -s nullglob
        docs+=(${dir}/${type}/${glob})
        shopt -u nullglob
    done
    if [ "${#docs[@]}" -gt 0 ]; then
        echo "${docs[@]}"
    else
        return 1
    fi
}

document_get() {
    local type idx docs glob doc docdirs dir
    idx="$1"
    type="$2"
    glob="$3"
    default_ext="${4:-$3}"
    case "$idx" in
        '')
            return 3
            ;;
        *[!0-9]*)
            # try getting a doc by name instead
            IFS=: read -a docdirs <<< "${cw_DOCUMENT_dir}:${CW_DOCPATH}"
            for dir in "${docdirs[@]}"; do
                doc=$(echo "${dir}"/${type}/${idx}${default_ext})
                if [ ! -f "${doc}" ]; then
                    doc=$(echo "${dir}"/${type}/[0-9]-${idx}${default_ext})
                    if [ ! -f "${doc}" ]; then
                        doc=$(echo "${dir}"/${type}/[0-9][0-9]-${idx}${default_ext})
                    fi
                fi
                if [ -f "${doc}" ]; then
                    break
                fi
            done
            if [ ! -f "${doc}" ]; then
                return 2
            fi
            echo "${doc}"
            ;;
        *)
            if [ "$idx" == 0 ]; then
                return 2
            fi
            if ! docs=($(document_list "${type}" "${glob}")); then
                return 1
            elif [ "$idx" -gt "${#docs[@]}" ]; then
                return 2
            else
                echo "${docs[$(($idx-1))]}"
            fi
            ;;
    esac
}
