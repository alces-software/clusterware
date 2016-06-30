
# Rename standard Clusterware setup function to not conflict with bats' setup
# function.
clusterware_setup() {
    local a xdg_config
    IFS=: read -a xdg_config <<< "${XDG_CONFIG_HOME:-$HOME/.config}:${XDG_CONFIG_DIRS:-/etc/xdg}"
    for a in "${xdg_config[@]}"; do
        if [ -e "${a}"/clusterware/config.vars.sh ]; then
            source "${a}"/clusterware/config.vars.sh
            break
        fi
    done
    if [ -z "${cw_ROOT}" ]; then
        echo "$0: unable to locate clusterware configuration"
        exit 1
    fi
    kernel_load
}

clusterware_setup
require slurm

setup() {
  # Create temporary slurm.conf file for each test.
  export cw_SLURM_CONFIG="$(mktemp /tmp/slurm.conf.XXXXXXXX)"
}

initial_slurm_config="$(cat <<-'EOF'
ConfigBefore
NodeName=PLACEHOLDER
ConfigBetween
PartitionName=all Nodes=PLACEHOLDER Default=YES MaxTime=UNLIMITED
ConfigAfter
EOF
)"

two_node_slurm_config="$(cat <<-'EOF'
ConfigBefore
NodeName=node01,node02
ConfigBetween
PartitionName=all Nodes=node01,node02 Default=YES MaxTime=UNLIMITED
ConfigAfter
EOF
)"

@test "slurm_add_compute_node adds nodes to config" {
  echo "${initial_slurm_config}" > "${cw_SLURM_CONFIG}"

  run slurm_add_compute_node node01

  run cat "${cw_SLURM_CONFIG}"
  [ "${lines[1]}" = 'NodeName=node01' ]
  [ "${lines[3]}" = 'PartitionName=all Nodes=node01 Default=YES MaxTime=UNLIMITED' ]

  run slurm_add_compute_node node02

  run cat "${cw_SLURM_CONFIG}"
  [ "${lines[1]}" = 'NodeName=node01,node02' ]
  [ "${lines[3]}" = 'PartitionName=all Nodes=node01,node02 Default=YES MaxTime=UNLIMITED' ]
}


@test "slurm_add_compute_node will not add an already present node" {
  echo "${two_node_slurm_config}" > "${cw_SLURM_CONFIG}"

  run slurm_add_compute_node node01

  run cat "${cw_SLURM_CONFIG}"
  [ "${lines[1]}" = 'NodeName=node01,node02' ]
  [ "${lines[3]}" = 'PartitionName=all Nodes=node01,node02 Default=YES MaxTime=UNLIMITED' ]
}

@test "slurm_remove_compute_node removes nodes from config" {
  echo "${two_node_slurm_config}" > "${cw_SLURM_CONFIG}"

  run slurm_remove_compute_node node02

  run cat "${cw_SLURM_CONFIG}"
  [ "${lines[1]}" = 'NodeName=node01' ]
  [ "${lines[3]}" = 'PartitionName=all Nodes=node01 Default=YES MaxTime=UNLIMITED' ]

  run slurm_remove_compute_node node01

  run cat "${cw_SLURM_CONFIG}"
  [ "${lines[1]}" = 'NodeName=PLACEHOLDER' ]
  [ "${lines[3]}" = 'PartitionName=all Nodes=PLACEHOLDER Default=YES MaxTime=UNLIMITED' ]
}

teardown() {
  # Remove test's temporary slurm.conf and slurm.conf lock file.
  rm ${cw_SLURM_CONFIG}{,.lock}
}
