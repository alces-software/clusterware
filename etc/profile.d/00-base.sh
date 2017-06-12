################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2008-2016 Alces Software Ltd
##
################################################################################
_cw_root() {
    _cw_ROOT=${_cw_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")"/../.. && pwd)}
    echo "${_cw_ROOT}"
}

alces() {
    local errlvl _cw_ROOT
    if [[ -t 1 && "$TERM" != linux ]]; then
        export cw_COLOUR=1
    else
        export cw_COLOUR=0
    fi
    _cw_ROOT="$(_cw_root)"
    [[ -s "${_cw_ROOT}"/bin/alces ]] && case $1 in
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
                        "${_cw_ROOT}"/bin/alces "$@" 0>&1 2>&1
                    else
                        "${_cw_ROOT}"/bin/alces "$@" 0>&1 2>&1 | less -FRX
                    fi
                    ;;
                *)
                    if [[ ":$cw_FLAGS:" =~ :nopager: ]]; then
                        eval $("${_cw_ROOT}"/bin/alces "$@") 2>&1
                    elif [ -n "$POSIXLY_CORRECT" ]; then
                        eval $("${_cw_ROOT}"/bin/alces "$@") 2>&1
                    elif [ "$2" == "load" -o "$2" == "add" ]; then
                        eval $("${_cw_ROOT}"/bin/alces "$@") 2>&1
                    else
                        local p
                        p="${_cw_ROOT}"
                        eval $(${p}/bin/alces "$@" 2> >(less -FRX >&2)) 2>&1
                    fi
                    ;;
            esac
            ;;
        gr*)
            case $2 in
                dep*)
                    case $3 in
                        en*|d*|p*|ini*|ins*)
                            eval $("${_cw_ROOT}"/bin/alces "$@") 2>&1
                            ;;
                        *)
                            "${_cw_ROOT}"/bin/alces "$@"
                            ;;
                    esac
                    ;;
                *)
                    "${_cw_ROOT}"/bin/alces "$@"
                    ;;
            esac
            ;;
        *)
            "${_cw_ROOT}"/bin/alces "$@"
            ;;
    esac
    errlvl=$?
    unset cw_COLOUR
    return $errlvl
}
if [ "$ZSH_VERSION" ]; then
  export alces _cw_root
else
  export -f alces _cw_root
fi
alias al=alces

export cw_SHELL=bash

if [ "$BASH_VERSION" ]; then
    _alces_action() {
        local cmds action
        action="$3"
        cmds=$(ls "${_cw_ROOT}"/libexec/${action}/actions)
        _alces_complete "$@" "$cmds"
    }

    _alces_repo_list_enabled() {
        local state="$1"
        ls -1 "${_cw_ROOT}"/etc/${state}
    }

    _alces_repo_list_avail() {
        local repo="$1"
        ls -1 "${_cw_ROOT}"/var/lib/${repo}/repos/*
    }

    _alces_repo_list_dirs() {
       local repo="$1" a
       for a in "${_cw_ROOT}"/var/lib/${repo}/repos/*/*; do
         if [ -d "$a" ]; then
           basename $a
         fi
       done
    }

    _alces_repo_list_disabled() {
        local repo="$1" state="$2"
        state="${state:-${repo}}"
        echo -e "$(_alces_repo_list_dirs "${repo}")\n$(ls -1 "${_cw_ROOT}"/etc/${state})" \
            | sed -r 's/^[0-9]+-//g' | sort | uniq -u
    }

    _alces_handler_action() {
        local cur="$1" prev="$2" values
        case $prev in
            d|di|dis|disa|disab|disabl|disable)
                values=$(_alces_repo_list_enabled "handlers")
                ;;
            e|en|ena|enab|enabl|enable)
                values="$(_alces_repo_list_disabled "handler" "handlers")"
                ;;
        esac
        echo "$values"
    }

    _alces_service_action() {
        local cur="$1" prev="$2" values
        case $prev in
            e|en|ena|enab|enabl|enable)
                values="$(alces service avail --components | sed -r "s:\x1B\[[0-9;]*[mK]::g" | grep -v '\[\*\]' | cut -f2- -d'/')"
                ;;
            i|in|ins|inst|insta|instal|install|b|bu|bui|buil|build)
                values="$(alces service avail | sed -r "s:\x1B\[[0-9;]*[mK]::g" |grep -v '\[\*\]' | cut -f2 -d'/')"
                ;;
        esac
        echo "$values"
    }

    _alces_howto_action() {
        local cur="$1" prev="$2" values
        case $prev in
            s|sh|sho|show)
                values="$(alces howto list | sed -r "s:\x1B\[[0-9;]*[mK]::g" | cut -c7- | awk '{print $1;}')"
                ;;
        esac
        echo "$values"
    }

    _alces_template_action() {
        local cur="$1" prev="$2" values
        case $prev in
            s|sh|sho|show|i|in|inf|info|c|co|cop|copy|p|pr|pre|prep|prepa|prepar|prepare)
                values="$(alces template list | sed -r "s:\x1B\[[0-9;]*[mK]::g" | cut -c7- | awk '{print $1;}')"
                ;;
        esac
        echo "$values"
    }

    _alces_storage_action() {
        local cur="$1" prev="$2" values
        case $prev in
            e|en|ena|enab|enabl|enable)
                values="$(alces storage avail | sed -r "s:\x1B\[[0-9;]*[mK]::g" | grep -v '\[\*\]' | cut -f2 -d'/')"
                ;;
            u|us|use)
                values="$(alces storage show | sed -r "s:\x1B\[[0-9;]*[mK]::g" | grep -v '\[\*\]' | awk '{print $3;}')"
                ;;
            f|fo|'for'|forg|forge|forget)
                values="$(alces storage show | sed -r "s:\x1B\[[0-9;]*[mK]::g" | cut -c5- | awk '{print $1;}')"
                ;;
            *)
                values="$(compgen -f -- "$cur")"
                ;;
            # TODO: get/put etc.
        esac
        echo "$values"
    }

    _alces_configure_action() {
        local cur="$1" prev="$2" values=""
        if (( COMP_CWORD == 3)); then
            case $prev in
                a|au|aut|auto|autos|autosc|autosca|autoscal|autoscali|autoscalin|autoscaling)
                    values="enable disable status"
                    ;;
                d|dr|dro|drop|dropc|dropca|dropcac|dropcach|dropcache)
                    values="pagecache slabobjs both"
                    ;;
                c|cl|clo|cloc|clock|clocks|clockso|clocksou|clocksour|clocksourc|clocksource)
                    values="default $(cat /sys/devices/system/clocksource/clocksource0/available_clocksource)"
                    ;;
                he|hel|help)
                    values=$(ls $(_cw_root)/libexec/configure/actions)
                    ;;
                hy|hyp|hyper|hypert|hyperth|hyperthr|hyperthre|hyperthrea|hyperthread|hyperthreadi|hyperthreadin|hyperthreading)
                    values="enable disable status"
                    ;;
                s|sc|sch|sche|sched|schedu|schedul|schedule|scheduler)
                    values="status allocation submission"
                    ;;
                t|th|thp)
                    values="enable disable status"
                    ;;
            esac
        elif [[ "scheduler" =~ ${COMP_WORDS[2]}* ]]; then
            values=$(_alces_configure_scheduler_action "$cur" "$prev")
        fi
        echo "$values"
    }

    _alces_configure_scheduler_action() {
        local cur="$1" prev="$2" values=""
        case $prev in
            a|al|all|allo|alloc|alloca|allocat|allocati|allocatio|allocation)
                values="packing spanning"
                ;;
            su|sub|subm|submi|submis|submiss|submissi|submissio|submission)
                values="all master none"
                ;;
        esac
        echo "$values"
    }

    _alces_session_action() {
        local cur="$1" prev="$2" values
        case $prev in
            k|ki|kil|kill|w|wa|wai|wait|i|in|inf|info|c|cl|cle|clea|clean)
                values="$(alces session list --identities 2>/dev/null)"
                ;;
            s|st|sta|star|start)
                values="$(_alces_repo_list_enabled "sessions")"
                ;;
            d|di|dis|disa|disab|disabl|disable)
                values=$(_alces_repo_list_enabled "sessions")
                ;;
            e|en|ena|enab|enabl|enable)
                values="$(_alces_repo_list_disabled "sessions")"
                ;;
        esac
        echo "$values"
    }

    _alces_customize_action() {
        local cur="$1" prev="$2"
        case $prev in
            slave)
                echo -e "add\nremove\nlist"
                ;;
        esac
    }

    _alces_complete() {
        local cur="$1" prev="$2" action="$3" values="$4"
        if ((COMP_CWORD == 2)); then
            case "$prev" in
                ser|serv|servi|servic|service)
                    values=$(echo $values | sed "s/\(build\)\|\(package\)//g")
                    ;;
            esac
            COMPREPLY=( $(compgen -W "$values" -- "$cur") )
        else
            case "${COMP_WORDS[2]}" in
                h|he|hel|help)
                    if ((COMP_CWORD == 3)); then
                        COMPREPLY=( $(compgen -W "$values" -- "$cur") )
                    fi
                ;;
                *)
                    values=""
                    case "${COMP_WORDS[1]}" in
                        ses|sess|sessi|sessio|session)
                            values=$(_alces_session_action "$cur" "$prev")
                            ;;
                        ha|han|hand|handl|handle|handler)
                            values=$(_alces_handler_action "$cur" "$prev")
                            ;;
                        ser|serv|servi|servic|service)
                            values=$(_alces_service_action "$cur" "$prev")
                            ;;
                        ho|how|howt|howto)
                            values=$(_alces_howto_action "$cur" "$prev")
                            ;;
                        t|te|tem|temp|templ|templa|templat|template)
                            values=$(_alces_template_action "$cur" "$prev")
                            ;;
                        st|sto|stor|stora|storag|storage)
                            values=$(_alces_storage_action "$cur" "$prev")
                            ;;
                        co|con|conf|confi|config|configu|configur|configure)
                            values=$(_alces_configure_action "$cur" "$prev")
                            ;;
                        cu|cus|cust|custo|custom|customi|customiz|customize)
                            values=$(_alces_customize_action "$cur" "$prev")
                            ;;
                    esac
                    if [ "$values" ]; then
                        COMPREPLY=( $(compgen -W "$values" -- "$cur") )
                    fi
                    ;;
            esac
        fi
    }

    _alces_storage() {
        _alces_complete "$@" "storage" \
                        "help enable configure forget use show avail put get rm list mkbucket rmbucket addbucket"
    }

    _alces_about() {
        local actions
        shopt -s nullglob
        for a in "${_cw_ROOT}"/etc/meta.d/*.rc; do
            actions="${actions} $(basename "$a" .rc)"
        done
        shopt -u nullglob
        COMPREPLY=( $(compgen -W "help ${actions}" -- "$cur") )
    }

    _alces() {
        local cur="$2" prev="$3" cmds opts _cw_ROOT

        COMPREPLY=()
        _cw_ROOT="$(_cw_root)"

        cmds=$(ls "${_cw_ROOT}"/libexec/actions)

        if ((COMP_CWORD == 1)); then
            COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
        else
            case "${COMP_WORDS[1]}" in
                a|ab|abo|abou|about)
                    _alces_about "$cur" "$prev" "about"
                    ;;
                co|con|conf|confi|config|configu|configur|configure)
                    _alces_action "$cur" "$prev" "configure"
                    ;;
                cu|cus|cust|custo|custom|customi|customiz|customize)
                    _alces_action "$cur" "$prev" "customize"
                    ;;
                g|gr|gri|grid|gridw|gridwa|gridwar|gridware)
                    _alces_gridware "$cur" "$prev"
                    ;;
                ha|han|hand|handl|handle|handler)
                    _alces_action "$cur" "$prev" "handler"
                    ;;
                help)
                    case "$cur" in
                        *)
                            COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
                            ;;
                    esac
                    ;;
                ho|how|howt|howto)
                    _alces_action "$cur" "$prev" "howto"
                    ;;
                m|mo|mod|modu|modul|module)
                    unset COMP_WORDS[0]
                    COMP_CWORD=$(($COMP_CWORD-1))
                    _module "module" "$cur" "$prev"
                    ;;
                ser|ser|serv|servi|servic|service)
                    _alces_action "$cur" "$prev" "service"
                    ;;
                ses|sess|sessi|sessio|session)
                    _alces_action "$cur" "$prev" "session"
                    ;;
                st|sto|stor|stora|storag|storage)
                    _alces_storage "$cur" "$prev"
                    ;;
                sy|syn|sync)
                    _alces_action "$cur" "$prev" "sync"
                    ;;
                t|te|tem|temp|templ|templa|templat|template)
                    _alces_action "$cur" "$prev" "template"
                    ;;
            esac
        fi
    }

    complete -F _alces alces al
fi
