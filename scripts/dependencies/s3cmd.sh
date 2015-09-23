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
detect_s3cmd() {
    [ -d "${target}/opt/s3cmd" ]
}

fetch_s3cmd() {
    title "Fetching s3cmd"
    if [ "$dep_source" == "fresh" ]; then
        fetch_source https://github.com/s3tools/s3cmd/releases/download/v1.6.0/s3cmd-1.6.0.tar.gz s3cmd-source.tar.gz
    else
        fetch_dist s3cmd
    fi
}

install_s3cmd() {
    title "Installing s3cmd"
    if [ "$dep_source" == "fresh" ]; then
        doing 'Extract'
        tar -C "${dep_build}" -xzf "${dep_src}/s3cmd-source.tar.gz"
        say_done $?

        cd "${dep_build}"/s3cmd-*

        doing 'Install'
        mkdir -p "${target}/opt/s3cmd"/{doc,man/man1}
        cp -R s3cmd S3 "${target}/opt/s3cmd"
        cp README.md "${target}/opt/s3cmd/doc"
        cp s3cmd.1 "${target}/opt/s3cmd/man/man1"
        say_done $?
    else
        install_dist s3cmd
    fi
}
