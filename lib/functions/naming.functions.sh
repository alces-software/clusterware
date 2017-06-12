#==============================================================================
# Copyright (C) 2015-2016 Stephen F. Norledge and Alces Software Ltd.
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
require files
require webapi

cw_NAMING_aws="${cw_ROOT}/opt/aws/bin/aws"
cw_NAMING_simp_le="${cw_ROOT}/opt/simp_le/bin/simp_le"
cw_NAMING_jq="${cw_ROOT}/opt/jq/bin/jq"

files_load_config --optional naming

naming_rr_exists() {
    local ignore_cname
    if [ "$1" == "--ignore-cname" ]; then
	ignore_cname=true
	shift
    fi
    result=$(naming_lookup_rr "$1")
    errlvl=$?
    if [ "${ignore_cname}" ]; then
	# if this is a CNAME, then the first line will not be an IP address
	echo "$result" | head -n1 | egrep -q '([1-2]?[0-9]{0,2}\.){3,3}[1-2]?[0-9]{0,2}'
    else
	return $errlvl
    fi
}

naming_lookup_rr() {
    local name ip
    name="$1"
    ip=$(dig +short "$name" 2>/dev/null)
    if [ "$ip" ]; then
        echo "$ip"
    else
        return 1
    fi
}

naming_perform_rr() {
    local operation name ip original_access_key original_secret_key
    operation="$1"
    name="$2"
    ip="$3"
    change_json=$(cat <<EOF
{
    "HostedZoneId": "${cw_NAMING_zoneid}",
    "ChangeBatch": {
        "Comment": "${operation} A record for ${name}",
        "Changes": [{ "Action": "${operation}", "ResourceRecordSet": {
            "Name": "${name}",
            "Type": "A", "TTL": 60, "Weight": 0,
            "SetIdentifier": "${cw_NAMING_secret}",
            "ResourceRecords": [{"Value": "${ip}"}]
        }}]
    }
}
EOF
)
    original_access_key="${AWS_ACCESS_KEY_ID}"
    original_secret_key="${AWS_SECRET_ACCESS_KEY}"
    AWS_ACCESS_KEY_ID="${cw_NAMING_access_key}"
    AWS_SECRET_ACCESS_KEY="${cw_NAMING_secret_key}"
    if [ -z "${AWS_ACCESS_KEY_ID}" -o -z "${AWS_SECRET_ACCESS_KEY}" ]; then
        echo "Unable to locate AWS credentials"
        AWS_ACCESS_KEY_ID="${original_access_key}"
        AWS_SECRET_ACCESS_KEY="${original_secret_key}"
        return 1
    fi

    export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
    "${cw_NAMING_aws}" route53 change-resource-record-sets \
        --cli-input-json "${change_json}"
    result="$?"

    AWS_ACCESS_KEY_ID="${original_access_key}"
    AWS_SECRET_ACCESS_KEY="${original_secret_key}"

    return $result
}

naming_create_rr() {
    naming_perform_rr "UPSERT" "$@"
}

naming_delete_rr() {
    naming_perform_rr "DELETE" "$@"
}

naming_cert_exists() {
    [ -f "${cw_ROOT}"/etc/ssl/cluster/cert.pem ]
}

naming_ping_cert() {
    local name meta k s output
    name="$1"
    s="$2"
    k="$3"
    meta="$4"
    output=$(cat <<JSON | webapi_post \
		     https://alces-custodian.herokuapp.com/ping
    {
	"name": "${name}",
        "secret": "${cw_NAMING_secret}",
        "s": "${s}",
        "k": "${k}",
        "meta": "${meta}"
    }
JSON
	  )
}

naming_fetch_cert() {
    local name names ip secret a k s
    name="$1"
    ip="$2"
    s="$3"
    k="$4"
    meta="$5"
    output=$(cat <<JSON | webapi_post \
		     https://alces-custodian.herokuapp.com/create
    {
	"name": "${name}",
	"ip": "${ip}",
        "secret": "${cw_NAMING_secret}",
        "s": "${s}",
        "k": "${k}",
        "meta": "${meta}"
    }
JSON
	  )
    errlvl="$?"
    if [ "${errlvl}" == "0" ]; then
	retry="$(echo "${output}" | "${cw_NAMING_jq}" -e -r .retry)"
	if [ $? == 0 ]; then
	    sleep $retry
	    # We use a high error code to distinguish this from a curl
	    # exit code (at time of writing, highest exit code of curl
	    # is 63).
	    return 147
	else
	    mkdir -p "${cw_ROOT}"/etc/ssl/cluster
	    touch "${cw_ROOT}"/etc/ssl/cluster/key.pem
	    chmod 0600 "${cw_ROOT}"/etc/ssl/cluster/key.pem
	    echo "${output}" | "${cw_NAMING_jq}" -r .fullchain > "${cw_ROOT}"/etc/ssl/cluster/fullchain.pem
	    echo "${output}" | "${cw_NAMING_jq}" -r .key > "${cw_ROOT}"/etc/ssl/cluster/key.pem
	    echo "${output}" | "${cw_NAMING_jq}" -r .cert > "${cw_ROOT}"/etc/ssl/cluster/cert.pem
	fi
    fi
    return ${errlvl}
}

naming_issue_cert() {
    local args name names path server_pid
    if [ ! -x "${cw_NAMING_simp_le}" ]; then
        return 1
    fi
    path=$(mktemp -d /tmp/clusterware.naming.XXXXXXXX)
    pushd ${path} &>/dev/null
    python -m SimpleHTTPServer 80 &>/dev/null &
    server_pid=$!
    popd &>/dev/null
    names=("$@" $(network_get_public_hostname))
    args=(--default_root ${path} -f account_key.json -f cert.pem -f fullchain.pem -f key.pem)
    for name in "${names[@]}"; do
        args+=(-d ${name})
    done
    mkdir -p "${cw_ROOT}"/etc/ssl/cluster
    chmod 0700 "${cw_ROOT}"/etc/ssl/cluster
    pushd "${cw_ROOT}"/etc/ssl/cluster &>/dev/null
    ${cw_NAMING_simp_le} "${args[@]}"
    errlvl=$?
    popd &>/dev/null
    kill ${server_pid}
    rm -rf "${path}"
    if [ $errlvl == 0 ]; then
        chmod 0600 "${cw_ROOT}"/etc/ssl/cluster/key.pem
        chmod 0755 "${cw_ROOT}"/etc/ssl/cluster
    elif [ $errlvl == 1 ]; then
        return 0
    fi
    return $errlvl
}

naming_issue_self_signed_cert() {
    local name unit output conf
    name="$1"
    unit="$2"
    output="$3"
    conf=$(mktemp /tmp/clusterware.naming.XXXXXXXX)
    cat <<EOF > "${conf}"
[ req ]
default_bits = 1024
distinguished_name = req_distinguished_name
prompt = no

[ req_distinguished_name ]
O = Alces Clusterware
OU = ${unit}
CN = ${name}
EOF
    mkdir -p "${output}"
    touch "${output}"/key.pem
    chmod 400 "${output}"/key.pem
    openssl genrsa 1024 > "${output}"/key.pem 2>/dev/null
    openssl req -config "${conf}" -new -x509 -nodes -sha1 -days 3650 \
	    -key "${output}"/key.pem > "${output}"/cert.pem
    cp "${output}"/cert.pem "${output}"/fullchain.pem
    rm -f "${conf}"
}
