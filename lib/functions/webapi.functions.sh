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
webapi_curl() {
    local url mimetype
    url="$1"
    mimetype="$2"
    shift 2

    curl "$@" -H "Accept: $mimetype" $url
}

webapi_post() {
    local url mimetype params
    url="$1"
    mimetype="${2:-application/vnd.api+json}"
    shift 2

    params=(-s -d @- -X POST "$@" -H "Content-Type: $mimetype")
    webapi_curl "${url}" "${mimetype}" "${params[@]}"
}

webapi_delete() {
    local url mimetype params
    url="$1"
    mimetype="${2:-application/vnd.api+json}"
    shift 2

    params=(-s -X DELETE "$@")
    webapi_curl "${url}" "${mimetype}" "${params[@]}"
}
