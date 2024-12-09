# Copyright © 1998-1999 Scriptics Corporation.
# Copyright © 2000 Ajuba Solutions
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

# You may distribute and/or modify this program under the terms of the GNU
# Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# See the file "COPYING" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

# all.tcl --
#
# This file contains a top-level script to run all of the Tcl
# tests.  Execute it by invoking "source all.tcl" when running tcltest
# in this directory.

package prefer latest
package require tcltest 2.5
namespace import ::tcltest::*

configure {*}$argv -testdir [file dirname [file dirname [file normalize [
    info script]/...]]]

if {[singleProcess]} {
    interp debug {} -frame 1
}

set ErrorOnFailures [info exists env(ERROR_ON_FAILURES)]
unset -nocomplain env(ERROR_ON_FAILURES)
if {[runAllTests] && $ErrorOnFailures} {exit 1}
# if calling direct only (avoid rewrite exit if inlined or interactive):
if { [info exists ::argv0] && [file tail $::argv0] eq [file tail [info script]]
  && !([info exists ::tcl_interactive] && $::tcl_interactive)
} {
    proc exit args {}
}
