#!/bin/bash
#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
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
require action
require ui
require files
require member

cw_CLOCKSOURCE_current_file=/sys/devices/system/clocksource/clocksource0/current_clocksource
cw_CLOCKSOURCE_config_file=${cw_ROOT}/etc/cluster-clocksource.rc
cw_CLOCKSOURCE_sym_link=${cw_ROOT}/var/lib/alces-flight-www/customizer/cluster-clocksource.rc

_clocksource_write_config() {
	local default="$1" clocksource="$2"
	shift 2

	cat <<EOF > $cw_CLOCKSOURCE_config_file
################################################################################
##
## Alces Clusterware - Clocksource configuration
## Copyright (c) 2017 Alces Software Ltd
##
################################################################################
cw_CLUSTER_default_clocksource=${default}
cw_CLUSTER_clocksource=${clocksource}
EOF
}

clocksource_get_available() {
	cat /sys/devices/system/clocksource/clocksource0/available_clocksource
}

clocksource_list() {
	local clocksources c cur indicator default_set
	files_load_config --optional cluster-clocksource
	clocksources="default $(clocksource_get_available)"
	cur=$(cat $cw_CLOCKSOURCE_current_file)
	
	if [[ ! -z "$cw_CLUSTER_clocksource" ]] && [[ "$cw_CLUSTER_clocksource" != "$cur" ]]; then
		action_die "conflict between system clocksource and config file"
	elif [[ -z "$cw_CLUSTER_default_clocksource" ]]; then
		default_set="default"
	fi

	for c in $clocksources; do
		indicator=" "
		if [[ $c == $cur ]] || [[ $c == "$default_set" ]]; then
			indicator="*"
		fi
		ui_print_enabled_status_line "$indicator" "" "$c" | sed "s/\///"
	done
}

_clocksource_is_master_node() {
	if [[ -z "$cw_INSTANCE_role" ]]; then
		files_load_config instance config/cluster
	fi
	if [[ "$cw_INSTANCE_role" == "master" ]]; then
		return 0
	else
		return 1
	fi
}

_clocksource_set_default() {
	if files_load_config --optional cluster-clocksource; then
		_clocksource_set_source "$cw_CLUSTER_default_clocksource" "true"
		rm -f $cw_CLOCKSOURCE_config_file $cw_CLOCKSOURCE_sym_link
	fi

}

_clocksource_set_source() {
	local input="$1" skip_write_config="$2" validated default
	shift 2

	validated=$(clocksource_get_available | grep -wo "$input")
	if [[ -z $validated ]]; then
		action_die "unrecognised clocksource: $input"
	fi
	echo $validated > $cw_CLOCKSOURCE_current_file

	if [[ "$skip_write_config" != "true" ]]; then
		if files_load_config --optional cluster-clocksource; then
			default="$cw_CLUSTER_default_clocksource"
		else
			default=$(cat $cw_CLOCKSOURCE_current_file)
		fi

		_clocksource_write_config "$default" "$validated"
		
		if _clocksource_is_master_node; then
			ln -fs $cw_CLOCKSOURCE_config_file $cw_CLOCKSOURCE_sym_link
		fi
	fi
}

_clocksource_ssh_compute_nodes() {
	local master_node="$1" cmd="$2" node="$4"
	shift 3

	if [[ "$master_node" != "$node" ]]; then
		ssh $node alces configure clocksource $cmd
	fi
}

clocksource_set() {
	local cmd="$1"
	shift

	if [[ "$cmd" == "default" ]]; then
		_clocksource_set_default
	else
		_clocksource_set_source "$cmd"
	fi

	if _clocksource_is_master_node; then
		member_each _clocksource_ssh_compute_nodes $(hostname) "$cmd"
	fi
}
