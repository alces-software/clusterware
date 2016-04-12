################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2008-2016 Alces Software Ltd
##
################################################################################
for a in modules modulerc; do
    if [ ! -f "$HOME/.$a" ]; then
        cp "$(_cw_root)"/etc/skel/$a "$HOME/.$a"
    fi
done

if [ -d "$(_cw_root)"/opt/Modules ]; then
    module() { alces module "$@" ; }
    if [ "$ZSH_VERSION" ]; then
        export module
    else
        export -f module
    fi
    MODULEPATH=`sed -n 's/[      #].*$//; /./H; $ { x; s/^\n//; s/\n/:/g; p; }' "$(_cw_root)"/etc/modulespath`
    if [ -f "$HOME/.modulespath" ]; then
        MODULEPATH=`sed -n 's/[     #].*$//; /./H; $ { x; s/^\n//; s/\n/:/g; p; }' "$HOME/.modulespath"`:$MODULEPATH
    fi
    export MODULEPATH="$(eval echo $MODULEPATH)"
fi
alias mod="alces module"

cw_silence_modules() {
    export cw_MODULES_VERBOSE_ORIGINAL=${cw_MODULES_VERBOSE}
    export cw_MODULES_RECORD_ORIGINAL=${cw_MODULES_RECORD}
    export cw_MODULES_RECORD=0
    export cw_MODULES_VERBOSE=0
}

cw_desilence_modules() {
    if [ "${cw_MODULES_VERBOSE_ORIGINAL}" ]; then
        export cw_MODULES_VERBOSE=${cw_MODULES_VERBOSE_ORIGINAL}
    else
        unset cw_MODULES_VERBOSE
    fi
    unset cw_MODULES_VERBOSE_ORIGINAL
    if [ "${cw_MODULES_RECORD_ORIGINAL}" ]; then
        export cw_MODULES_RECORD=${cw_MODULES_RECORD_ORIGINAL}
    else
        unset cw_MODULES_RECORD
    fi
    unset cw_MODULES_RECORD_ORIGINAL
}

if [ -z "${cw_MODULES_VERBOSE}" ]; then
    export cw_MODULES_VERBOSE=1
fi

# Source modules from home directory
if [ -f ~/.modules ]; then
    source ~/.modules
fi

if [ "$BASH_VERSION" ]; then
#
# Bash commandline completion (bash 3.0 and above) for Modules 3.2.9
#
    _module_avail() {
        "$(_cw_root)"/opt/Modules/bin/modulecmd bash -t avail 2>&1 | sed '
                /:$/d;
                /:ERROR:/d;
                s#^\(.*\)/\(.\+\)(default)#\1\n\1\/\2#;
                s#/(default)##g;
                s#/*$##g;'
    }

    _module_avail_specific() {
        "$(_cw_root)"/opt/Modules/bin/modulecmd bash -t avail 2>&1 | sed '
                /:$/d;
                /:ERROR:/d;
                s#^\(.*\)/\(.\+\)(default)#\1\/\2#;
                s#/(default)##g;
                s#/*$##g;'
    }

    _module_not_yet_loaded() {
        comm -23  <(_module_avail|sort)  <(tr : '\n' <<<${LOADEDMODULES}|sort)
    }

    _module_long_arg_list() {
        local cur="$1" i

        if [[ ${COMP_WORDS[COMP_CWORD-2]} == sw* ]]
        then
            COMPREPLY=( $(compgen -W "$(_module_not_yet_loaded)" -- "$cur") )
            return
        fi
        for ((i = COMP_CWORD - 1; i > 0; i--))
        do case ${COMP_WORDS[$i]} in
                add|load)
                    COMPREPLY=( $(compgen -W "$(_module_not_yet_loaded)" -- "$cur") )
                    break;;
                rm|remove|unload|switch|swap)
                    COMPREPLY=( $(IFS=: compgen -W "${LOADEDMODULES}" -- "$cur") )
                    break;;
            esac
        done
    }

    _module() {
        local cur="$2" prev="$3" cmds opts

        COMPREPLY=()

        cmds="add apropos avail clear display help\
              initadd initclear initlist initprepend initrm initswitch\
              keyword list load purge refresh rm show swap switch\
              unload unuse update use whatis"

        opts="-c -f -h -i -l -s -t -u -v -H -V\
              --create --force  --help  --human   --icase\
              --long   --silent --terse --userlvl --verbose --version"

        case "$prev" in
            add|load)   COMPREPLY=( $(compgen -W "$(_module_not_yet_loaded)" -- "$cur") );;
            rm|remove|unload|switch|swap)
                COMPREPLY=( $(IFS=: compgen -W "${LOADEDMODULES}" -- "$cur") );;
            unuse)              COMPREPLY=( $(IFS=: compgen -W "${MODULEPATH}" -- "$cur") );;
            use|*-a*)   ;;                      # let readline handle the completion
            -u|--userlvl)       COMPREPLY=( $(compgen -W "novice expert advanced" -- "$cur") );;
            display|help|show|whatis)
                COMPREPLY=( $(compgen -W "$(_module_avail)" -- "$cur") );;
            *) if test $COMP_CWORD -gt 2
then
    _module_long_arg_list "$cur"
else
    case "$cur" in
                # The mappings below are optional abbreviations for convenience
        ls)     COMPREPLY="list";;      # map ls -> list
        r*)     COMPREPLY="rm";;        # also covers 'remove'
        sw*)    COMPREPLY="switch";;

        -*)     COMPREPLY=( $(compgen -W "$opts" -- "$cur") );;
        *)      COMPREPLY=( $(compgen -W "$cmds" -- "$cur") );;
    esac
fi;;
        esac
    }

    _alces_gridware_list() {
        "$(_cw_root)"/bin/alces gridware list 2>&1 | sed '
                s#^\(.*\)/\(.\+\)(default)#\1\n\1\/\2#;
                s#/*$##g; s#^base/##g;'
    }

    _alces_package_list_expired() {
        if (($(date +%s)-$cw_PACKAGE_LIST_MTIME > 60)); then
            return 0
        else
            return 1
        fi
    }

    _alces_gridware() {
        local cur="$1" prev="$2" cmds opts
        cmds="clean default help info install list purge update import export depot search requires"
        if ((COMP_CWORD > 2)); then
            case "$prev" in
                in*|r*)
                    if [ -z "$cw_PACKAGE_LIST" ] || _alces_package_list_expired; then
                        cw_PACKAGE_LIST=$(_alces_gridware_list)
                        cw_PACKAGE_LIST_MTIME=$(date +%s)
                    fi
                    COMPREPLY=( $(compgen -W "$cw_PACKAGE_LIST" -- "$cur") )
                    ;;
                p*|c*|def*|e*|l*)
                    # for purge, clean and default, we provide a module list
                    COMPREPLY=( $(compgen -W "$(_module_avail_specific)" -- "$cur") )
                    ;;
                dep*)
                    COMPREPLY=( $(compgen -W "list enable disable update info install purge init" -- "$cur") )
                    ;;
                *)
                    # for purge, clean and default, we provide a module list
                    COMPREPLY=( $(compgen -f -- "$cur") )
                    ;;
            esac
        else
            case "$prev" in
                *)
                    COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
                    ;;
            esac
        fi
    }

    complete -o default -F _module module mod
fi
