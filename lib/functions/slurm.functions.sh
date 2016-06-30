#==============================================================================
# Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
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
require network
require ruby

files_load_config --optional cluster-slurm

export cw_SLURM_CONFIG="$cw_ROOT/opt/slurm/etc/slurm.conf"

slurm_log() {
    local message
    message="$1"
    log "${message}" "${cw_CLUSTER_SLURM_log}"
}

_modify_compute_nodes() {
    local functions_dir script
    functions_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    script="${functions_dir}/share/slurm-modify-compute-nodes.rb"

    ruby_exec "${script}" "$@"
}

slurm_add_compute_node() {
    local node_name="$1"
    _modify_compute_nodes add "${node_name}"
}

slurm_remove_compute_node() {
    local node_name="$1"
    _modify_compute_nodes remove "${node_name}"
}

slurm_control_node_iptables_rule() {
    local compute_node_ip interface
    compute_node_ip="$1"
    interface="$(network_get_route_iface ${compute_node_ip})"

    # Master node should accept requests on all ports for communication back
    # from nodes' slurmstepd daemons. In future may want to specify
    # SrunPortRange but this is fine for now.
    echo "INPUT -i ${interface} -s ${compute_node_ip} -p tcp -j ACCEPT"
}

slurm_compute_node_iptables_rule() {
    local control_node_ip interface
    control_node_ip="$1"
    interface="$(network_get_route_iface ${control_node_ip})"

    # Compute nodes should accept requests from master node to their slurmd.
    echo "INPUT -i "${interface}" -s "${control_node_ip}" -p tcp --dport 6818 -j ACCEPT"
}
