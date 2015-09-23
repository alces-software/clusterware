################################################################################
##
## Alces Clusterware - Environment modules enhancements
## Copyright (c) 2008-2015 Alces Software Ltd
##
################################################################################
namespace eval ::alces {
    namespace ensemble create
    namespace export once getenv try-deeper try-next pretty

    # mitigates the side-effect caused by modulerc files being loaded
    # twice during some module commands.
    proc once {body} {
        variable SeenFiles

        if {[info exists SeenFiles($::ModulesCurrentModulefile)] == 0 } { 
            set SeenFiles($::ModulesCurrentModulefile) 1
            eval $body
        }
    }

    proc getenv {var {fallback ""}} {
        if {[info exists ::env($var)] == 1} {
            return $::env($var)
        } {
            return $fallback
        }
    }

    proc pretty {module} {
        if {[alces getenv alces_COLOUR 0]} {
            set p [split $module "/"]
            set reset {[0m}
            set s ""
            for { set i 0 } { $i < [llength $p]} { incr i } {
                if { $i == 0 } {
                    set c {[38;5;5m}
                } elseif { $i == 1 } {
                    set c {[38;5;221m}
                } elseif { $i == 2 } {
                    set c {[38;5;74m}
                } else {
                    set c {[38;5;68m}
                }
                set s "${s}${c}[lindex $p $i]${reset}/"
            }
            set s [string trim $s "/"]
            return $s
        } else {
            return $module
        }
    }

    # set variable/version to allow access to one level further down
    # the modulefile tree for the specified
    # module. ie. mpi/openmpi/gcc -> mpi/openmpi/<version>/gcc.  This
    # should be called from a .modulerc file in the directory to be
    # enabled.
    proc try-deeper {} {
        variable NextModule
        set n [module-info name]
        if {$n == ""} { return }
        
        set nc [llength [split $n "/"]]
        set p [split [module-info specified] "/"]
        set pc [llength $p]
        set d [lindex $p $pc-1]
        
        if {$nc >= $pc || $d == "default"} { return "default" }

        module-version $n/default $d
        #puts stderr "setting path for $d to $n/default"
        #puts stderr "setting NextModule to: $d"
        set NextModule $d
    }

    # inform modules of the modulefile to try to low based on the
    # previous invocation of try-deeper. This should be called from a
    # .version file in the lower level directory.
    proc try-next {} {
        variable NextModule
        if {[info exists NextModule] == 1 } { 
            if {$NextModule != "default"} {
                # puts stderr "setting ModulesVersion to: $NextModule"
                set ::ModulesVersion $NextModule
            }
        }
    }
}

interp hide {} conflict module-conflict
interp hide {} prereq module-prereq
if {[alces getenv alces_COLOUR 0]} {
    set ok {[0;32mOK[0m}
    set skipped {[0;33mSKIPPED[0m}
    set failed {[0;31mFAILED[0m}
    set alt {[0;43;30mVARIANT[0m}
} else {
    set ok OK
    set skipped SKIPPED
    set failed FAILED
    set alt VARIANT
}

proc ::conflict {module} {
    if { [module-info mode display] } {
        interp invokehidden {} -global module-conflict $module
    } {
        ::module-log error null
        if { [catch {interp invokehidden {} -global module-conflict $module}] } {
            ::module-log error stderr
            # query LOADEDMODULES environment variable for the precise module that conflicts
            set existing [extract-current ${module}]
            set msg "alternative module ([alces pretty $existing]) already loaded"
            if { [alces getenv alces_INTERNAL] != "" } {
                set ::env(alces_INTERNAL_RESULT) $msg
            } {
                puts stderr "Unable to load [alces pretty [module-info name]] -- ${msg}."
            }
            exit 1
        }
    }
}

proc ::prereq {module} {
    if { [module-info mode display] } {
        interp invokehidden {} -global module-prereq $module
    } {
        ::module-log error null
        if { [catch {interp invokehidden {} -global module-prereq $module}] } {
            ::module-log error stderr
            if { [alces getenv alces_INTERNAL 0] == 0 } {
                puts stderr "Required module ($module) could not be loaded."
            }
            exit 1
        }
    }
}

proc ::process {body} {
    set original_processing 0
    if { [alces getenv alces_MODULES_VERBOSE 0] } {
	variable ok
	set original_branch [alces getenv alces_INTERNAL_BRANCH]
	set original_trunk [alces getenv alces_INTERNAL_TRUNK]
	processing
	if { [info exists ::env(alces_INTERNAL_PROCESSING)] == 0 } {
	    set ::env(alces_INTERNAL_PROCESSING) true
	    set original_processing 1
	}
	set ::env(alces_INTERNAL_BRANCH) "[alces getenv alces_INTERNAL_TRUNK] | -- "
	set ::env(alces_INTERNAL_TRUNK) "[alces getenv alces_INTERNAL_TRUNK] |   "
	eval $body
	set ::env(alces_INTERNAL_BRANCH) $original_branch
	set ::env(alces_INTERNAL_TRUNK) $original_trunk
	if { [module-info mode load] && $original_processing == 1 } {
	    puts stderr "[alces getenv alces_INTERNAL_TRUNK] |\n[alces getenv alces_INTERNAL_TRUNK] $ok"
	    unset ::env(alces_INTERNAL_PROCESSING)
	}
    } {
	if { [info exists ::env(alces_INTERNAL_PROCESSING)] == 0 } {
	    set ::env(alces_INTERNAL_PROCESSING) true
	    set original_processing 1
	}
	eval $body
	if { [module-info mode load] && $original_processing == 1 } {
	    unset ::env(alces_INTERNAL_PROCESSING)
	}
    }

    if { [module-info mode load] && ( [info exists ::env(alces_MODULES_RECORD)] == 0 || $::env(alces_MODULES_RECORD) != 0 ) } {
	set m [module-info name]
	if { [info exists ::env(alces_LOADED_MODULES)] == 0 } {
	    set ::env(alces_LOADED_MODULES) $m
	} else {
	    set ::env(alces_LOADED_MODULES) $::env(alces_LOADED_MODULES):$m
	}

	if { [info exists original_processing] && $original_processing == 1 } {
	    catch {
		set t [clock clicks -milliseconds]
		set filename /opt/gridware/etc/.access/$t.$::env(USER).[pid].txt
		set fileId [open $filename "w"]
		puts $fileId "$t [pid] $::env(USER) $::env(alces_LOADED_MODULES)"
		close $fileId
	    }
	    unset ::env(alces_LOADED_MODULES)
	}
    }
}

proc ::extract-current {module_prefix} {
    set p [split $::env(LOADEDMODULES) ":"]
    set match_idx [lsearch -glob $p "$module_prefix/*"]
    set match [lindex $p $match_idx]
    return $match
}

proc ::alt-is-loaded {module} {
    set p [split $module "/"]

    for { set i [expr [llength $p] - 2] } { $i >= 1 } { incr i -1 } {
        set m [join [lrange $p 0 $i] "/"]
        if { [is-loaded ${m}] == 1 } {
            set ::env(alces_INTERNAL_ALT) [extract-current ${m}]
            return 1
        }
    }
    return 0
}

proc ::processing {} {
    variable ok
    variable skipped
    variable alt

    set m [module-info name]

    if { [module-info mode load] } {
        if { [info exists ::env(alces_INTERNAL_PROCESSING)] == 0 } {
            puts -nonewline stderr "[alces getenv alces_INTERNAL_BRANCH][alces pretty ${m}]"
        }
        if { [is-loaded ${m}] == 1 } {
            puts stderr " ... $skipped (already loaded)"
            break
        } elseif { [alt-is-loaded ${m}] == 1 } {
            puts stderr " ... $alt (have alternative: [alces pretty $::env(alces_INTERNAL_ALT)])"
            break
        } else {
            puts stderr ""
        }
    }
    if { [module-info mode remove] } {
        if { [string length ${m}] > 40 } {
            puts stderr "[alces pretty ${m}] ...\n[format {%40s} {}]     UNLOADING --> $ok"
        } {
            set a [string length $m]
            set b [string length [alces pretty $m]]
            set width [expr 40 + $b - $a]
            puts stderr "[format "%${width}s" [alces pretty ${m}]] ... UNLOADING --> $ok"
        }
    }
}

proc ::search {module version specific {internal 0}} {
    set m [module-info alias ${module}-${specific}]
    if { ${m} == "*undef*" } {
        if { $internal } {
            set ::env(alces_INTERNAL_FELLBACK) 1
        }
        # couldn't locate specific version we were compiled against,
        # let's try something a little less specific
        set m [module-info alias ${module}-${version}]
        if { ${m} == "*undef*" } {
            # hmm, can't find the right version either.  Fallback to
            # looking for a default version.
            set m [module-info alias ${module}]
        }
    }
    return $m
}

proc ::depend {module {version ""} {specific ""}} {
    variable ok
    variable skipped
    variable failed
    variable alt
    if { [module-info mode display] } {
        set m [search ${module} ${version} ${specific}]
        if { ${m} == "*undef*" } {
            interp invokehidden {} -global module-prereq "MISSING (${module})"
        } else {
            interp invokehidden {} -global module-prereq ${m}
        }
    } {
        if { [module-info mode load] } {
            set using_alt 0
            set using_fallback 0
            set m [search ${module} ${version} ${specific} 1]
            if { [alces getenv alces_INTERNAL_FELLBACK 0] } {
                set ::env(alces_INTERNAL_FELLBACK) 0
                set using_fallback 1
            }
            if { ${m} == "*undef*" } {
                puts stderr "[alces getenv alces_INTERNAL_BRANCH][alces pretty ${module}] ... $failed -- unable to resolve alias"
                exit 1
            }

	    if { [alces getenv alces_MODULES_VERBOSE 0] } {
		puts -nonewline stderr "[alces getenv alces_INTERNAL_BRANCH]"
		if { $using_fallback } {
		    puts -nonewline stderr "$alt "
		}
		puts -nonewline stderr "[alces pretty ${m}]"
	    }

            if { [is-loaded ${m}] == 0 && [alt-is-loaded ${m}] == 1 } {
                set msg " ... $alt (have alternative: [alces pretty $::env(alces_INTERNAL_ALT)])"
                set using_alt 1
            } elseif { [is-loaded ${m}] == 0 } {
                set ::env(alces_INTERNAL) 1
                module-log error null
                module load $m
                module-log error stderr
                set msg "[alces getenv alces_INTERNAL_TRUNK] * --> $ok"
            } else {
                set msg " ... $skipped (already loaded)"
            }
            if { $using_alt == 0 && [catch {prereq $m}] } {
                puts stderr "[alces getenv alces_INTERNAL_TRUNK] * --> $failed $m -- [alces getenv alces_INTERNAL_RESULT]"
                set ::env(alces_INTERNAL_RESULT) "prerequisite not met ($m)"
                exit 1
            }
	    if { [alces getenv alces_MODULES_VERBOSE 0] } {
		puts stderr "${msg}"
	    }
        }
    }
}
