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
vnc_create_password() {
    dd if=/dev/urandom bs=16 count=1 2>/dev/null | base64 | tr -d '/+' | cut -c1-8
}

vnc_create_password_file() {
    local password sessiondir
    password="$1"
    sessiondir="$2"

    echo "${password}" | "${VNCPASSWD}" -f > "${sessiondir}/password.dat"
    chmod 0600 "${sessiondir}/password.dat"
    files_mark_tempfile "${sessiondir}/password.dat"
}

vnc_session_start() {
    local password sessiondir
    password="$1"
    sessiondir="$2"
    shift 2

    vnc_create_password_file "${password}" "${sessiondir}"
    vnc_start_server "${sessiondir}" "$@"
}

vnc_start_server() {
    local sessiondir
    sessiondir="$1"
    shift

    $VNCSERVER -autokill \
        -sessiondir "${sessiondir}" \
        -sessionscript "${sessiondir}/session.sh" \
        -vncpasswd "${sessiondir}/password.dat" \
        -exedir "${VNCBIN}" \
        "$@" 2>"${sessiondir}/vncserver.err" > "${sessiondir}/vncserver.out"

    files_mark_tempfile "${sessiondir}/vncserver.out"
    files_mark_tempfile "${sessiondir}/vncserver.err"
}

vnc_read_vars() {
    local sessiondir
    sessiondir="$1"
    grep "^{EVAL}" "${sessiondir}/vncserver.out" | cut -c7-
}

vnc_write_vars_file() {
    local sessiondir address display port password metadata_file
    sessiondir="$1"
    address="$2"
    display="$3"
    port=$(($display+5900))
    password="$4"
    websocket="$5"

    metadata_file="${sessiondir}/metadata.vars.sh"

    files_mark_tempfile "${metadata_file}"

    cat <<EOF > "${metadata_file}"
vnc[DISPLAY]="${display}"
vnc[PORT]="${port}"
vnc[PASSWORD]="${password}"
vnc[ADDRESS]="${address}"
vnc[WEBSOCKET]="${websocket}"
EOF
    chmod 0600 "${metadata_file}"
}

vnc_write_detail_file() {
    local sessiondir address display password detail_file
    sessiondir="$1"
    address="$2"
    display="$3"
    password="$4"

    detail_file="${sessiondir}/details.txt"

    files_mark_tempfile "${detail_file}"

    vnc_emit_details "$address" "$display" "$password" > "${detail_file}"
    chmod 0600 "${detail_file}"
}

vnc_emit_details() {
    local address display password port
    address="$1"
    display="$2"
    password="$3"

    port=$(($display+5900))
    cat <<EOF
VNC server started:
Identifier: $SESSIONID
      Host: $address
      Port: $port
   Display: $display
  Password: $password

Depending on your client, you can connect to the session using:

  vnc://${USER}:${password}@${address}:${port}
  ${address}:${port}
  ${address}:${display}

If prompted, you should supply the following password: ${password}

EOF
}

vnc_kill_server() {
    local sessiondir
    sessiondir="$1"
    $VNCSERVER -kill -sessiondir ${sessiondir} &> "${sessiondir}/vncserver.kill.log"
}

vnc_cleanup() {
    local display sessiondir
    display="$1"
    sessiondir="$2"

    debug "terminating VNC server process (:${display})"
    vnc_kill_server "${sessiondir}" &> "${sessiondir}/vncserver.kill.log"
    files_mark_tempfile "${sessiondir}/vncserver.kill.log"
}

vnc_session_clean() {
    local sessiondir skip_running sessionid shortid pidfile
    if [ "$1" == "--skip-running" ]; then
        skip_running=true
        shift
    fi
    sessiondir="$1"

    if [ -d "$sessiondir" ]; then
        pidfile="$sessiondir"/vncserver.pid
        sessionid=$(basename "$sessiondir")
        shortid=$(echo "$sessionid" | cut -f1 -d'-')

        if [ -f "${sessiondir}/starting.txt" ]; then
            if [ ! "$skip_running" ]; then
                say "session $shortid is starting up - use kill to terminate first!"
            fi
        elif ! pgrep -F $pidfile &>/dev/null; then
            say "cleaned session $shortid"
            rm -rf "$sessiondir"
        elif [ ! "$skip_running" ]; then
            say "session $shortid is still running - use kill to terminate first!"
        fi
    else
        say "no matching session could be found"
    fi
}

vnc_session_kill() {
    local sessiondir sessionid shortid pidfile
    sessiondir="$1"
    if [ -d "$sessiondir" ]; then
        sessionid=$(basename "$sessiondir")
        shortid=$(echo "$sessionid" | cut -f1 -d'-')
        pidfile="$sessiondir"/vncserver.pid
        if pgrep -F $pidfile &>/dev/null; then
            if vnc_kill_server "${sessiondir}" &>/dev/null; then
                say "session ${shortid} has been terminated"
            else
                say "session ${shortid} could not be terminated"
                bail 1
            fi
        else
            say "session ${shortid} is already dead - use clean to cleanup"
        fi
    else
        say "no matching session could be found"
    fi
}

vnc_session_wait() {
    local sessiondir sessionid shortid pidfile
    sessiondir="$1"
    if [ -d "$sessiondir" ]; then
        sessionid=$(basename "$sessiondir")
        shortid=$(echo "$sessionid" | cut -f1 -d'-')
        pidfile="$sessiondir"/vncserver.pid
        say "waiting for session ${shortid} to complete..."
        while pgrep -F $pidfile &>/dev/null; do
            sleep 1
        done
        say "session ${shortid} completed at $(date "+%Y-%m-%d %H:%M:%S")"
    fi
}

vnc_find_sessiondir() {
    local sessionid sessiondir
    sessionid="$1"
    sessiondir=$(echo "${SESSIONSDIR}"/${sessionid}-*)
    if [ ! -d "${sessiondir}" ]; then
        sessiondir=$(echo "${SESSIONSDIR}"/${sessionid})
    fi
    if [ ! -d "${sessiondir}" ]; then
        return 1
    else
        echo "${sessiondir}"
    fi
}