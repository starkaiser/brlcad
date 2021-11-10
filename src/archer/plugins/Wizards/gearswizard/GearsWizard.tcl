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
# Description:
#	 This is an Archer plugin for building gear drives geometry.
#

::itcl::class GearsWizard {
    inherit Wizard

    constructor {_archer _wizardTop _wizardState _wizardOrigin _originUnits args} {}
    destructor {}

    public {
	# Override's for the Wizard class
	common wizardMajorType $Archer::pluginMajorTypeWizard
	common wizardMinorType $Archer::pluginMinorTypeMged
	common wizardName "Gears Wizard"
	common wizardVersion "0.1"
	common wizardClass GearsWizard

	# Methods that override Wizard methods
	method setWizardState {_wizardState}

	method drawGears {}
	method buildGears {}
	method buildGearsXML {}
	
    }

    protected {
		# Input parameters for the drive
		# angles - deg; distances and module - mm; others - unitless
		variable gearRatio 1.0
		variable pressureAngle 20.0
		variable helixAngle 0.0
		variable module 1.0
		variable centerDistance 15.0
		variable totalProfileShift 0.0
		variable numberOfTeeth1 10
		variable numberOfTeeth2 20
		variable facewidth1 10.0
		variable facewidth2 10.0
		variable profileShift1 0.0
		variable profileShift2 0.0
		# middle gap for double helical gears (0 - herringbone gears)
		variable middleGap1 0.0
		variable middleGap2 0.0
		
		# Variables for checkboxes
		variable enablePinion 1
		variable enableGear 1
		variable enableGearUnitSize 0
		variable strengthCalculation 1
		variable doubleHelical 0
		
		variable inputType "Number of Teeth"
		variable designGuide "Total Profile Shift"
		variable driveType "Pinion and Gear"
		variable dimensionsDisplay "Pinion"
		
		# Variables for the unit sizes of the gears
		# all values here - unitless
		variable unitSizeA1 1.0
		variable unitSizeC1 0.25
		variable unitSizeR1 0.35
		variable unitSizeA2 1.0
		variable unitSizeC2 0.25
		variable unitSizeR2 0.35
		
		# Variables to display results and the technical drawing of a general drive
		variable resultsDesign
		variable drawing
		
		# Variables for strength calculation
		# power - kW; speed - rpm; torque - Nm; bending stress - MPa; others - unitless
		variable power1 0.01
		variable power2 1.5
		variable speed1 100.0
		variable speed2 1.5
		variable torque1 1.5
		variable torque2 1.5
		
		variable efficiency 0.98
		
		variable bendingStress1 150.0
		variable bendingStress2 150.0
		
		variable safetyFactor 1.5
		
		variable loadType "Power, Speed -> Torque"
		variable resultsStrength
	
	method initWizardState {}
	method buildParameter {parent}
	method buildParameterView {parent}

	method addWizardAttrs {obj {onlyTop 1}}
    }

    private {
    }
}

## - constructor
#
#
#
::itcl::body GearsWizard::constructor {_archer _wizardTop _wizardState _wizardOrigin _originUnits args} {
    global env

    itk_component add pane {
	iwidgets::panedwindow $itk_interior.pane \
	    -orient vertical
    } {}

    buildParameter $itk_interior
    # don't need this (I think)
    #grid rowconfigure $itk_interior 0 -weight 1
    #grid columnconfigure $itk_interior 0 -weight 1
    set archer $_archer
    set archersGed [Archer::pluginGed $archer]

    # process options
    eval itk_initialize $args

    set wizardTop $_wizardTop
    setWizardState $_wizardState
    set wizardOrigin $_wizardOrigin
    set wizardAction buildGears
    set wizardXmlAction buildGearsXML
    set wizardUnits in

    set savedUnits [$archersGed units -s]
    $archersGed units $_originUnits
    set sf1 [$archersGed local2base]
    $archersGed units $wizardUnits
    set sf2 [$archersGed base2local]
    set sf [expr {$sf1 * $sf2}]
    set wizardOrigin [vectorScale $wizardOrigin $sf]
    $archersGed units $savedUnits
}

::itcl::body GearsWizard::destructor {} {
    # nothing for now
}

::itcl::body GearsWizard::setWizardState {_wizardState} {
    set wizardState $_wizardState
    initWizardState
}





::itcl::body GearsWizard::initWizardState {} {
    foreach {vname val} $wizardState {
	if {[info exists $vname]} {
	    set $vname $val
	}
    }

}

::itcl::body GearsWizard::buildParameter {parent} {
    buildParameterView $parent
    
    # don't need this (I think)
    #grid rowconfigure $parent 0 -weight 1
    #grid columnconfigure $parent 0 -weight 1
}


::itcl::body GearsWizard::buildParameterView {parent} {
    # Create a tabnotebook
    itk_component add tabNoteBook {
		::ttk::notebook $parent.noteBook
    } {}
    
    
    # Create the frame for the design tab
    itk_component add paramDesignTab {
		::ttk::frame $itk_component(tabNoteBook).designTab
    } {}
    
    # Create the frame for the strength calculations
    itk_component add paramStrengthTab {
		::ttk::frame $itk_component(tabNoteBook).strengthTab
    } {}
    
    
    # Create the common parameters label and frame
	itk_component add paramCommonL {
		::ttk::label $itk_component(paramDesignTab).commonL \
	    -text "Common Parameters"
	} {}
    itk_component add paramCommonFrame {
	    ::ttk::frame  $itk_component(paramDesignTab).commonFrame 
	} {}
    
    
    # Labels for the input common parameters
    itk_component add paramGearRatioL {
		::ttk::label $itk_component(paramCommonFrame).gearRatioL \
	    -text "Gear Ratio:"
	} {}
	
	itk_component add paramModuleL {
		::ttk::label $itk_component(paramCommonFrame).moduleL \
	    -text "Module (mm):"
	} {}
	
	itk_component add paramPressureAngleL {
		::ttk::label $itk_component(paramCommonFrame).pressureAngleL \
	    -text "Pressure Angle (deg):"
	} {}
	
	itk_component add paramHelixAngleL {
		::ttk::label $itk_component(paramCommonFrame).helixAngleL \
	    -text "Helix Angle (deg)"
	} {}
	
	itk_component add paramCenterDistanceL {
		::ttk::label $itk_component(paramCommonFrame).centerDistanceL \
	    -text "Center Distance (mm):" \
	} {}
	
	itk_component add paramTotalProfileShiftL {
		::ttk::label $itk_component(paramCommonFrame).totalProfileShiftL \
	    -text "Total Profile Shift (mm):" \
	} {}
	
	# Entries for the common input parameters
	itk_component add paramGearRatioE {
	::ttk::entry $itk_component(paramCommonFrame).gearRatioE \
	    -textvariable [::itcl::scope gearRatio] \
	    -width 10
    } {}
    
    itk_component add paramModuleE {
	::ttk::entry $itk_component(paramCommonFrame).moduleE \
	    -textvariable [::itcl::scope module] \
	    -width 10
    } {}
    
    itk_component add paramPressureAngleE {
	::ttk::entry $itk_component(paramCommonFrame).pressureAngleE \
	    -textvariable [::itcl::scope pressureAngle] \
	    -width 10
    } {}
    
    itk_component add paramHelixAngleE {
	::ttk::entry $itk_component(paramCommonFrame).helixAngleE \
	    -textvariable [::itcl::scope helixAngle] \
	    -width 10
    } {}
    
    itk_component add paramCenterDistanceE {
	::ttk::entry $itk_component(paramCommonFrame).centerDistanceE \
	    -textvariable [::itcl::scope centerDistance] \
	    -width 10
    } {}
    
    itk_component add paramTotalProfileShiftE {
	::ttk::entry $itk_component(paramCommonFrame).totalProfileShiftE \
	    -textvariable [::itcl::scope totalProfileShift] \
	    -width 10
    } {}
    
    # Create the image for the technical drawing
    image create photo imageSpur \
    -file /home/starkaiser/CodingProjects/brlcad/src/archer/plugins/Wizards/gearswizard/images/gear_spur.png \
    -width 200 \
    -height 200
    itk_component add paramImageFrame {
	    iwidgets::labeledframe  $itk_component(paramDesignTab).imageFrame \
	    -labelimage imageSpur
	} {}
    
    
    
    # Create empty label
    itk_component add emptyL {
	::ttk::label $itk_component(paramDesignTab).emptyL \
	    -text "" \
	    -anchor e
    } {}
    
    # Create the individual parameters label and frame
	itk_component add paramIndL {
		::ttk::label $itk_component(paramDesignTab).indL \
	    -text "Individual Parameters"
	} {}
    itk_component add paramIndFrame {
	    ::ttk::frame  $itk_component(paramDesignTab).indFrame 
	} {}
	
    
    itk_component add paramPinionCB {
	::ttk::checkbutton $itk_component(paramIndFrame).pinionCB \
	    -text "Pinion" \
	    -variable [::itcl::scope enablePinion]
    } {}
    
    itk_component add paramGearCB {
	::ttk::checkbutton $itk_component(paramIndFrame).gearCB \
	    -text "Gear" \
	    -variable [::itcl::scope enableGear]
    } {}
    
    
    # Labels for the input individual parameters
    itk_component add paramNumberTeeth1L {
		::ttk::label $itk_component(paramIndFrame).numberTeeth1L \
	    -text "Number of Teeth"
	} {}
	itk_component add paramNumberTeeth2L {
		::ttk::label $itk_component(paramIndFrame).numberTeeth2L \
	    -text "Number of Teeth"
	} {}
	
	itk_component add paramFacewidth1L {
		::ttk::label $itk_component(paramIndFrame).facewidth1L \
	    -text "Facewidth"
	} {}
	itk_component add paramFacewidth2L {
		::ttk::label $itk_component(paramIndFrame).facewidth2L \
	    -text "Facewidth"
	} {}
	
	itk_component add paramProfileShift1L {
		::ttk::label $itk_component(paramIndFrame).profileShift1L \
	    -text "Profile Shift"
	} {}
	itk_component add paramProfileShift2L {
		::ttk::label $itk_component(paramIndFrame).profileShift2L \
	    -text "Profile Shift"
	} {}
	
	itk_component add paramGap1L {
		::ttk::label $itk_component(paramIndFrame).gap1L \
	    -text "Middle Gap"
	} {}
	itk_component add paramGap2L {
		::ttk::label $itk_component(paramIndFrame).gap2L \
	    -text "Middle Gap"
	} {}
	
	
	# Entries for the individual input parameters
	itk_component add paramNumberTeeth1E {
	::ttk::entry $itk_component(paramIndFrame).numberTeeth1E \
	    -textvariable [::itcl::scope numberOfTeeth1] \
	    -width 10
    } {}
    itk_component add paramNumberTeeth2E {
	::ttk::entry $itk_component(paramIndFrame).numberTeeth2E \
	    -textvariable [::itcl::scope numberOfTeeth2] \
	    -width 10
    } {}
    
    itk_component add paramFacewidth1E {
	::ttk::entry $itk_component(paramIndFrame).facewidth1E \
	    -textvariable [::itcl::scope facewidth1] \
	    -width 10
    } {}
    itk_component add paramFacewidth2E {
	::ttk::entry $itk_component(paramIndFrame).facewidth2E \
	    -textvariable [::itcl::scope facewidth2] \
	    -width 10
    } {}
    
    itk_component add paramProfileShift1E {
	::ttk::entry $itk_component(paramIndFrame).profileShift1E \
	    -textvariable [::itcl::scope profileShift1] \
	    -width 10
    } {}
    itk_component add paramProfileShift2E {
	::ttk::entry $itk_component(paramIndFrame).profileShift2E \
	    -textvariable [::itcl::scope profileShift2] \
	    -width 10 
    } {}
    
    itk_component add paramGap1E {
	::ttk::entry $itk_component(paramIndFrame).gap1E \
	    -textvariable [::itcl::scope middleGap1] \
	    -width 10
    } {}
    itk_component add paramGap2E {
	::ttk::entry $itk_component(paramIndFrame).gap2E \
	    -textvariable [::itcl::scope middleGap2] \
	    -width 10
    } {}
    
    $itk_component(tabNoteBook) add $itk_component(paramDesignTab) -text "Design" 
    $itk_component(tabNoteBook) add $itk_component(paramStrengthTab) -text "Strength Calculation" 
    
    #pack $itk_component(paramCommonL) -anchor nw
    #pack $itk_component(paramCommonFrame) -anchor nw
    
    set row 0
    set col 0
    
    grid $itk_component(paramCommonL) -row $row -stick nsew
	incr row
	grid $itk_component(paramCommonFrame) -row $row -stick nsew
	incr row
	grid $itk_component(emptyL) -row $row -stick nsew
	incr row
	grid $itk_component(paramIndL) -row $row -stick nsew
	incr row
	grid $itk_component(paramIndFrame) -row $row -stick nsew
	#grid $itk_component(paramImageFrame) -row $row -column 1 -stick nsew
    
    set row 0
    grid $itk_component(paramGearRatioL) $itk_component(paramGearRatioE) \
	-row $row -stick nsew
    incr row
    grid $itk_component(paramModuleL) $itk_component(paramModuleE) \
	-row $row -stick nsew
    incr row
    grid $itk_component(paramPressureAngleL) $itk_component(paramPressureAngleE) \
	-row $row -stick nsew
    incr row
    grid $itk_component(paramHelixAngleL) $itk_component(paramHelixAngleE) \
	-row $row -stick nsew
    incr row
    grid $itk_component(paramCenterDistanceL) $itk_component(paramCenterDistanceE) \
	-row $row -stick nsew
    incr row
    grid $itk_component(paramTotalProfileShiftL) $itk_component(paramPressureAngleE) \
	-row $row -stick nsew
	
	
	set row 0
	grid $itk_component(paramPinionCB) $itk_component(paramGearCB) \
	-row $row -stick nsew
	incr row
	grid $itk_component(paramNumberTeeth1L) $itk_component(paramNumberTeeth2L) \
	-row $row -stick nsew
	incr row
	grid $itk_component(paramNumberTeeth1E) $itk_component(paramNumberTeeth2E) \
	-row $row -stick nsew
	incr row
	grid $itk_component(paramFacewidth1L) $itk_component(paramFacewidth2L) \
	-row $row -stick nsew
	incr row
	grid $itk_component(paramFacewidth1E) $itk_component(paramFacewidth2E) \
	-row $row -stick nsew
	incr row
	grid $itk_component(paramProfileShift1L) $itk_component(paramProfileShift2L) \
	-row $row -stick nsew
	incr row
	grid $itk_component(paramProfileShift1E) $itk_component(paramProfileShift2E) \
	-row $row -stick nsew
	incr row
	grid $itk_component(paramGap1L) $itk_component(paramGap2L) \
	-row $row -stick nsew
	incr row
	grid $itk_component(paramGap1E) $itk_component(paramGap2E) \
	-row $row -stick nsew

    pack $itk_component(tabNoteBook) -expand 1 -fill both
}

::itcl::body GearsWizard::addWizardAttrs {obj {onlyTop 1}} {
    if {$onlyTop} {
	$archersGed attr set $obj \
	    WizardTop $wizardTop
    } else {
	$archersGed attr set $obj \
	    WizardName $wizardName \
	    WizardClass $wizardClass \
	    WizardTop $wizardTop \
	    WizardState $wizardState \
	    WizardOrigin $wizardOrigin \
	    WizardUnits $wizardUnits \
	    WizardVersion $wizardVersion
    }
}







::itcl::body GearsWizard::drawGears {} {
    $archersGed configure -autoViewEnable 0
    $archersGed draw $wizardTop
    $archersGed refresh_all
    $archersGed configure -autoViewEnable 1
}

::itcl::body GearsWizard::buildGears {} {
    
}

::itcl::body GearsWizard::buildGearsXML {} {
}

# Local Variables:
# mode: Tcl
# tab-width: 8
# c-basic-offset: 4
# tcl-indent-level: 4
# indent-tabs-mode: t
# End:
# ex: shiftwidth=4 tabstop=8
