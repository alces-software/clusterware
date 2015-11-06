################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2008-2015 Alces Software Ltd
##
################################################################################
alces() {
    local errlvl
    if [[ -t 1 && "$TERM" != linux ]]; then
        export cw_COLOUR=1
    else
        export cw_COLOUR=0
    fi
    [[ -s "/opt/clusterware/bin/alces" ]] && case $1 in
        mo*)
            if [[ ! $(ps -o 'command=' -p "$$" 2>/dev/null) =~ ^- ]]; then
                # Not an interactive shell
                if [[ ! ":$cw_FLAGS:" =~ :verbose-modules: ]]; then
                    export cw_MODULES_VERBOSE=0
                fi
            fi
            case $2 in
                al*|h*|-h|--help)
                    if [[ ":$cw_FLAGS:" =~ :nopager: ]]; then
                        "/opt/clusterware/bin/alces" "$@" 0>&1 2>&1
                    else
                        "/opt/clusterware/bin/alces" "$@" 0>&1 2>&1 | less -FRX
                    fi
                    ;;
                *)
                    if [[ ":$cw_FLAGS:" =~ :nopager: ]]; then
                        eval $(/opt/clusterware/bin/alces "$@") 2>&1
                    elif [ -n "$POSIXLY_CORRECT" ]; then
                        eval $(/opt/clusterware/bin/alces "$@") 2>&1
                    else
                        eval $(/opt/clusterware/bin/alces "$@" 2> >(less -FRX >&2)) 2>&1
                    fi
                    ;;
            esac
            ;;
        gr*)
            case $2 in
                dep*)
                    case $3 in
                        e*|d*)
                            eval $(/opt/clusterware/bin/alces "$@") 2>&1
                            ;;
                        *)
                            "/opt/clusterware/bin/alces" "$@"
                            ;;
                    esac
                    ;;
                *)
                    "/opt/clusterware/bin/alces" "$@"
                    ;;
            esac
            ;;
        *)
            "/opt/clusterware/bin/alces" "$@"
            ;;
    esac
    errlvl=$?
    unset cw_COLOUR
    return $errlvl
}
if [ "$ZSH_VERSION" ]; then
  export alces
else
  export -f alces
fi
alias al=alces

export cw_SHELL=bash

if [ "$BASH_VERSION" ]; then
    _alces() {
        local cur="$2" prev="$3" cmds opts

        COMPREPLY=()

        cmds=$(ls /opt/clusterware/libexec/actions)

        if ((COMP_CWORD == 1)); then
            COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
        else
            if type _alces_gridware &>/dev/null; then
                case "${COMP_WORDS[1]}" in
                    gr*)
                        _alces_gridware "$cur" "$prev"
                        ;;
                    mo*)
                        unset COMP_WORDS[0]
                        COMP_CWORD=$(($COMP_CWORD-1))
                        _module "module" "$cur" "$prev"
                        ;;
                    *)
                        case "$cur" in
                            *)
                                COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
                                ;;
                        esac
                        ;;
                esac
            else
                COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
            fi
        fi
    }

    complete -o default -F _alces alces al
fi
