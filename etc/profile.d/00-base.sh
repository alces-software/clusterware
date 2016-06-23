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
  export alces
else
  export -f alces
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

    _alces_repo_list_disabled() {
        local repo="$1" state="$2"
        state="${state:-${repo}}"
        echo -e "$(ls -1 "${_cw_ROOT}"/var/lib/${repo}/repos/*)\n$(ls -1 "${_cw_ROOT}"/etc/${state})" \
            | sort | uniq -u
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
                values="$(alces service avail --components | sed -r "s:\x1B\[[0-9;]*[mK]::g" | grep -v '\[\*\]' | cut -f2 -d'/')"
                ;;
            i|in|ins|inst|insta|instal|install|b|bu|bui|buil|build)
                values="$(alces service avail | sed -r "s:\x1B\[[0-9;]*[mK]::g" |grep -v '\[\*\]' | cut -f2 -d'/')"
                ;;
        esac
        echo "$values"
    }

    _alces_service_action() {
        local cur="$1" prev="$2" values
        case $prev in
            e|en|ena|enab|enabl|enable)
                values="$(alces service avail --components | sed -r "s:\x1B\[[0-9;]*[mK]::g" | grep -v '\[\*\]' | cut -f2 -d'/')"
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
            s|sh|sho|show|i|in|inf|info|c|co|cop|copy)
                values="$(alces template list | sed -r "s:\x1B\[[0-9;]*[mK]::g" | cut -c7- | awk '{print $1;}')"
                ;;
        esac
        echo "$values"
    }

    _alces_storage_action() {
        local cur="$1" prev="$2" values
        case $prev in
            e|en|ena|enab|enabl|enable)
                values="$(alces storage avail --backends | sed -r "s:\x1B\[[0-9;]*[mK]::g" | grep -v '\[\*\]' | cut -f2 -d'/')"
                ;;
            u|us|use)
                values="$(alces storage avail | sed -r "s:\x1B\[[0-9;]*[mK]::g" | grep -v '\[\*\]' | awk '{print $1;}')"
                ;;
            f|fo|'for'|forg|forge|forget)
                values="$(alces storage avail | sed -r "s:\x1B\[[0-9;]*[mK]::g" | cut -c5- | awk '{print $1;}')"
                ;;
            *)
                values="$(compgen -f -- "$cur")"
                ;;
            # TODO: get/put etc.
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

    _alces_complete() {
        local cur="$1" prev="$2" action="$3" values="$4"
        if ((COMP_CWORD == 2)); then
            COMPREPLY=( $(compgen -W "$values" -- "$cur") )
        else
            case ${COMP_WORDS[2]} in
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
                        "help enable configure forget use avail put get rm list mkbucket rmbucket addbucket"
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
                g|gr|gri|grid|gridw|gridwa|gridwar|gridware)
                    _alces_gridware "$cur" "$prev"
                    ;;
                m|mo|mod|modu|modul|module)
                    unset COMP_WORDS[0]
                    COMP_CWORD=$(($COMP_CWORD-1))
                    _module "module" "$cur" "$prev"
                    ;;
                st|sto|stor|stora|storag|storage)
                    _alces_storage "$cur" "$prev"
                    ;;
                ha|han|hand|handl|handle|handler)
                    _alces_action "$cur" "$prev" "handler"
                    ;;
                c|co|con|conf|confi|config|configu|configur|configure)
                    _alces_action "$cur" "$prev" "configure"
                    ;;
                a|ab|abo|abou|about)
                    _alces_action "$cur" "$prev" "about"
                    ;;
                ho|how|howt|howto)
                    _alces_action "$cur" "$prev" "howto"
                    ;;
                ser|ser|serv|servi|servic|service)
                    _alces_action "$cur" "$prev" "service"
                    ;;
                ses|sess|sessi|sessio|session)
                    _alces_action "$cur" "$prev" "session"
                    ;;
                t|te|tem|temp|templ|templa|templat|template)
                    _alces_action "$cur" "$prev" "template"
                    ;;
                help)
                    case "$cur" in
                        *)
                            COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
                            ;;
                    esac
                    ;;
            esac
        fi
    }

    complete -F _alces alces al
fi