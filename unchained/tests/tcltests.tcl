#! /usr/bin/env tclsh

# You may distribute and/or modify this program under the terms of the GNU
# Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# See the file "COPYING" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

# Don't overwrite tcltests facilities already present
if {[package provide tcltests] ne {}} return

package require tcltest 2.5
namespace import ::tcltest::*
testConstraint exec [llength [info commands exec]]
testConstraint debug [tcl::build-info debug]
testConstraint purify [tcl::build-info purify]
testConstraint debugpurify [
    expr {
	![tcl::build-info memdebug]
	&& [testConstraint debug]
	&& [testConstraint purify]
    }]
testConstraint bigmem [expr {[
	info exists ::env(TCL_TESTCONSTRAINT_BIGMEM)]
		? !!$::env(TCL_TESTCONSTRAINT_BIGMEM)
		: 1
}]
testConstraint fcopy         [llength [info commands fcopy]]
testConstraint fileevent     [llength [info commands fileevent]]
testConstraint thread        [expr {![catch {package require Thread 2.7-}]}]
testConstraint notValgrind   [expr {![testConstraint valgrind]}]


namespace eval ::tcltests {


    proc init {} {
	if {[namespace which ::tcl::file::tempdir] eq {}} {
	    interp alias {} [namespace current]::tempdir {} [
		namespace current]::tempdir_alternate
	} else {
	    interp alias {} [namespace current]::tempdir {} ::tcl::file::tempdir
	}
    }


    # Stolen from dict.test
    proc scriptmemcheck script {
	set end [lindex [split [memory info] \n] 3 3]
	for {set i 0} {$i < 5} {incr i} {
	    uplevel 1 $script
	    set tmp $end
	    set end [lindex [split [memory info] \n] 3 3]
	}
	expr {$end - $tmp}
    }


    proc tempdir_alternate {} {
	close [file tempfile tempfile]
	set tmpdir [file dirname $tempfile]
	set execname [info nameofexecutable]
	regsub -all {[^[:alpha:][:digit:]]} $execname _ execname
	for {set i 0} {$i < 10000} {incr i} {
	    set time [clock milliseconds]
	    set name $tmpdir/${execname}_${time}_$i
	    if {![file exists $name]} {
		file mkdir $name
		return $name
	    }
	}
	error [list {could not create temporary directory}]
    }

    # Generates test cases for 0, min and max number of arguments for a command.
    # Expected result is as generated by Tcl_WrongNumArgs
    # Only works if optional arguments come after fixed arguments
    # E.g.
    #  testnumargs "zipfs mount" "" "?mountpoint? ?zipfile? ?password?"
    #  testnumargs "lappend" "varName" "?value ...?"
    proc testnumargs {cmd {fixed {}} {optional {}} args} {
	variable count
	set minargs [llength $fixed]
	set maxargs [expr {$minargs + [llength $optional]}]
	if {[regexp {\.\.\.\??$} [lindex $optional end]]} {
	    unset maxargs; # No upper limit on num of args
	}
	set message "wrong # args: should be \"$cmd"
	if {[llength $fixed]} {
	    append message " $fixed"
	}
	if {[llength $optional]} {
	    append message " $optional"
	}
	if {[llength $fixed] == 0 && [llength $optional] == 0} {
	    append message " \""
	} else {
	    append message "\""
	}
	set label [join $cmd -]
	if {$minargs > 0} {
	    set arguments [lrepeat [expr {$minargs-1}] x]
	    test $label-minargs-[incr count($label-minargs)] \
		"$label no arguments" \
		-body "$cmd" \
		-result $message -returnCodes error \
		{*}$args
	    if {$minargs > 1} {
		test $label-minargs-[incr count($label-minargs)] \
		    "$label missing arguments" \
		    -body "$cmd $arguments" \
		    -result $message -returnCodes error \
		    {*}$args
	    }
	}
	if {[info exists maxargs]} {
	    set arguments [lrepeat [expr {$maxargs+1}] x]
	    test $label-maxargs-[incr count($label-maxargs)] \
		"$label extra arguments" \
		-body "$cmd $arguments" \
		-result $message -returnCodes error \
		{*}$args
	}
    }

    init

    package provide tcltests 0.1
}

