#                G E A R S W I Z A R D . T C L
# BRL-CAD
#
# Copyright (c) 2002-2021 United States Government as represented by
# the U.S. Army Research Laboratory.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this file; see the file named COPYING for more
# information.
#
###
#
# Description -
#	 This is a script for loading/registering the gears wizard.
#

set brlcadDataPath [file join [bu_dir data] plugins]
# puts "pwd is [pwd], path is $brlcadDataPath"
set filename [file join $brlcadDataPath archer Wizards gearswizard GearsWizard.tcl]
if { ![file exists $filename] } {
    puts "Could not load the GearsWizard plugin, skipping $filename"
    return
}
source $filename

# Load only once
set pluginMajorType $GearsWizard::wizardMajorType
set pluginMinorType $GearsWizard::wizardMinorType
set pluginName $GearsWizard::wizardName
set pluginVersion $GearsWizard::wizardVersion

# check to see if already loaded
set plugin [Archer::pluginQuery $pluginName]
if {$plugin != ""} {
    if {[$plugin get -version] == $pluginVersion} {
	# already loaded ... don't bother doing it again
	return
    }
}

set iconPath ""

# register plugin with Archer's interface
Archer::pluginRegister $pluginMajorType \
    $pluginMinorType \
    $pluginName \
    "GearsWizard" \
    "GearsWizard.tcl" \
    "Build gear drives." \
    $pluginVersion \
    "Sorin Cătălin Păștiță" \
    $iconPath \
    "Build a gear drive object" \
    "buildGears" \
    "buildGearsXML"

# Local Variables:
# mode: Tcl
# tab-width: 8
# c-basic-offset: 4
# tcl-indent-level: 4
# indent-tabs-mode: t
# End:
# ex: shiftwidth=4 tabstop=8
