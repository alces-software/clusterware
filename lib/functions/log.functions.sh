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
cw_LOG_default_log="/var/log/clusterware/instance.log"

log() {
    local message logfile
    message="$1"
    logfile="$2"
    if [ "$logfile" == '-' ]; then
        echo "$(date +"%b %e %H:%M:%S") ${message}"
    elif [ "$logfile" ]; then
        echo "$(date +"%b %e %H:%M:%S") ${message}" >> "$logfile"
    else
        echo "$(date +"%b %e %H:%M:%S") ${message}" > /dev/stderr
    fi
}

log_blob() {
    local logfile prefix message date
    logfile="$1"
    prefix="$2"
    date="$(date +"%b %e %H:%M:%S")"
    if [ "$prefix" ]; then
        prefix="${date} [${prefix}]"
    else
        prefix="${date}"
    fi
    if [ "$logfile" == '-' ]; then
        sed "s/^/${prefix} /g"
    elif [ "$logfile" ]; then
        sed "s/^/${prefix} /g" >> "$logfile"
    else
        sed "s/^/${prefix} /g" > /dev/stderr
    fi
}
