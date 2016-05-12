################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2008-2016 Alces Software Ltd
##
################################################################################
foreach a ( modules modulerc )
    if ( ! -f "$HOME/.$a" ) then
        cp _ROOT_/etc/skel/$a "$HOME/.$a"
    endif
end

set exec_prefix='_ROOT_/opt/Modules/bin'

set prefix=""
set postfix=""

if ( $?histchars ) then
  set histchar = `echo $histchars | cut -c1`
  set _histchars = $histchars

  set prefix  = 'unset histchars;'
  set postfix = 'set histchars = $_histchars;'
else
  set histchar = \!
endif

if ($?prompt) then
  set prefix  = "$prefix"'set _prompt="$prompt";set prompt="";'
  set postfix = "$postfix"'set prompt="$_prompt";unset _prompt;'
endif

if ($?noglob) then
  set prefix  = "$prefix""set noglob;"
  set postfix = "$postfix""unset noglob;"
endif
set postfix = "set _exit="'$status'"; $postfix; test 0 = "'$_exit;'

alias module $prefix'eval `'$exec_prefix'/modulecmd '$cw_SHELL' '$histchar'*`; '$postfix

if (! $?MODULEPATH ) then
    setenv MODULEPATH `sed -n 's/[      #].*$//; /./H; $ { x; s/^\n//; s/\n/:/g; p; }' _ROOT_/etc/gridware/global/modulespath`
    if ( -f "$HOME/.modulespath" ) then
      set usermodulepath = `sed -n 's/[     #].*$//; /./H; $ { x; s/^\n//; s/\n/:/g; p; }' "$HOME/.modulespath"`
      setenv MODULEPATH "$usermodulepath":"$MODULEPATH"
    endif
    setenv MODULEPATH `eval echo $MODULEPATH`
endif

if (! $?LOADEDMODULES ) then
  setenv LOADEDMODULES ""
endif

alias mod 'module'

if (! $?cw_MODULES_RECORD ) then
  setenv cw_MODULES_RECORD 0
endif

alias cw_silence_modules 'setenv cw_MODULES_VERBOSE_ORIGINAL "$cw_MODULES_VERBOSE"; setenv cw_MODULES_VERBOSE 0; setenv cw_MODULES_RECORD_ORIGINAL "$cw_MODULES_RECORD"; setenv cw_MODULES_RECORD 0'
alias cw_desilence_modules 'setenv cw_MODULES_VERBOSE "$cw_MODULES_VERBOSE_ORIGINAL"; unsetenv cw_MODULES_VERBOSE_ORIGINAL; setenv cw_RECORD_VERBOSE "$cw_MODULES_RECORD_ORIGINAL"; unsetenv cw_MODULES_RECORD_ORIGINAL'

if (! $?cw_MODULES_VERBOSE ) then
    setenv cw_MODULES_VERBOSE 1
endif

#source modules file from home dir
if ( -r ~/.modules ) then
  source ~/.modules
endif

unset exec_prefix
unset prefix
unset postfix
