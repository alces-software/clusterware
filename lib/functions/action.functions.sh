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
if [ "$cw_DEBUG" ]; then
  set -x
fi

if [ "$cw_BINNAME" ]; then
  cw_BINNAME="$cw_BINNAME $(basename "$0")"
else
  cw_BINNAME="$(basename "$0")"
fi

trap "action_exit 1" TERM INT

case ${cw_SETTINGS_theme:-standard} in
    dark)
        cw_THEME_prim=${cw_THEME_prim:-74}
        cw_THEME_sec1=${cw_THEME_sec1:-68}
        cw_THEME_sec2=${cw_THEME_sec2:-221}
        cw_THEME_mid=${cw_THEME_mid:-169}
        cw_THEME_comp=${cw_THEME_comp:-215}
    ;;
    light)
        cw_THEME_prim=${cw_THEME_prim:-31}
        cw_THEME_sec1=${cw_THEME_sec1:-61}
        cw_THEME_sec2=${cw_THEME_sec2:-172}
        cw_THEME_mid=${cw_THEME_mid:-90}
        cw_THEME_comp=${cw_THEME_comp:-130}
    ;;
    *)
        cw_THEME_prim=${cw_THEME_prim:-67}
        cw_THEME_sec1=${cw_THEME_sec1:-68}
        cw_THEME_sec2=${cw_THEME_sec2:-172}
        cw_THEME_mid=${cw_THEME_mid:-127}
        cw_THEME_comp=${cw_THEME_comp:-136}
    ;;
esac

action_always_murder() {
  # ensure all children die when we do
  trap "if [ -z \"\$cw_CLEANED\" ]; then export PGID=\$BASHPID; ( /bin/kill -- -\$PGID &>/dev/null ) & fi" EXIT
}

action_exit() {
    action_cleanup
    # ensure all our (owned) children die
    cw_CLEANED=true
    export PGID=$BASHPID; ( /bin/kill -- -$PGID &>/dev/null ) &
    exit $1
}

action_emit() {
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

action_warn() {
    local msg
    msg="$1"
    sed "s/^/$cw_BINNAME: /g" <<< "${msg}" 1>&2
}

action_die() {
    local msg
    msg="$1"
    errlvl="${2:-1}"
    action_warn "$msg"
    action_exit $errlvl
}

action_debug() {
    local msg
    msg="$1"

    if [ "$cw_DEBUG" ]; then
        echo "<<debug>> ${msg}"
    fi
}

action_check_progs() {
    local progs p r
    progs="dirname $*"
    for p in $progs; do
        r=$(type -p $p)
        if [ $? != 0 -o ! -x "$r" ]; then
            action_die "unable to locate required program: $p"
        fi
    done
}

action_cleanup() {
  # Override this in other scripts as necessary
  :
}
