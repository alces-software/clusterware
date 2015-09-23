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
alces_BINNAME="$alces_BINNAME $(basename "$0")"

fail_hook() {
    return 1
}

fail() {
    local ref try
    if [ "$1" == "-" ]; then
        shift
        try=1
    fi
    ref=$1
    if [ -z "$ref" ]; then
        ref=E01
    fi
    fail_hook "$@"
    case $ref in
        X*)
            local binary
            if [ "$2" ]; then
                binary=" ($2)"
            fi
            fail_with "$ref" "This system does not provide a binary${binary} that this process requires."
            ;;
        C*)
            fail_with "$ref" "Unfortunately {{ operation_name }} was unsuccessful due to a network tool error."
            ;;
        H*)
            fail_with "$ref" "Unfortunately {{ operation_name }} was unsuccessful due to a communications error."
            ;;
        *)
            if [ -z "$try" ]; then
                fail_with "$ref" "Unfortunately {{ operation_name }} could not be completed."
            fi
            ;;
    esac
}

fail_with() {
    local ref msg
    ref="$1"
    msg="$2"
    emit "$2"
    emit <<EOF

Please contact Alces Customer Support <support@alces-software.com> for further details. [Error reference: $ref]
EOF
    bail 1
}

bail() {
    cleanup
    exit $1
}

emit() {
    if [ ! -x "$(type -p fold)" ]; then
        if [ "$1" ]; then
            echo "$*" | fold -s
        else
            cat | fold -s
        fi
    else
        if [ "$1" ]; then echo "$*"; else cat; fi
    fi
}

say() {
    local msg
    msg="$1"

    echo "$alces_BINNAME: ${msg}"
}

debug() {
    local msg
    msg="$1"

    if [ "$alces_DEBUG" ]; then
        echo "<<debug>> ${msg}"
    fi
}

check_progs() {
    local progs n p r
    progs="dirname $*"
    n=0
    for p in $progs; do
        n=$(($n+1))
        r=$(type -p $p)
        if [ $? != 0 -o ! -x "$r" ]; then
            fail "X0$n" "$p"
        fi
    done
}

cleanup() {
  # Override this in other scripts as necessary
  :
}

wait_for_pid() {
    local pid
    pid=$1
    while [ -d /proc/$pid ]; do
        sleep 5 &
        # Wait for the backgrounded sleep to complete. Running the sleep in the
        # background, allows this process to be responsive to any signals it
        # receives.
        wait $!
    done
}
