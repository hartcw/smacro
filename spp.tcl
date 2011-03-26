#!/usr/bin/env tclsh
# Finds and processes source file templates that have embedded TCL code blocks

set options(Input)      ""
set options(Output)     "output"
set options(Verbose)    1
set options(ScriptDir)  ""
set options(ScriptName) "smacro.tcl"
set options(ScriptFile) "smacro.tcl"

proc PrintMessage { message } {

    global options

    if { $options(Verbose) } {
        puts $message
    }
}

proc PrintError { error } {

    puts "ERROR: $error"
}

proc ProcessFile { filename } {

    global options

    set dstFile [file join $options(Output) $filename]
    set dstPath [file dirname $dstFile]

    # Ensure the target directory exists
    if { [file exists $dstPath] == 0 } {

        file mkdir $dstPath
    }

    set expType ""

    switch -- [file extension $filename] {
        ".htm" -
        ".html" {
            set expType "xml"
        }
        ".h" -
        ".hpp" -
        ".c" -
        ".cc" -
        ".cpp" {
            set expType "cpp"
        }
        ".js" -
        ".css" {
            set expType "c++"
        }
    }

    if { $expType != "" } {

        # Process the file through the smacro script
        PrintMessage "Processing: $filename"
        smacro::Process $filename $dstFile $expType ""

    } else {

        # Just copy it across
        PrintMessage "Copying:    $filename"
        file copy -force -- $filename $dstFile
    }
}

proc ProcessPath { path } {

    global options

    # Find files in this directory
    set files [glob -nocomplain -directory $path -types f -- *]

    # Now process each file
    foreach file [lsort $files] {

        ProcessFile $file
    }

    # Retrieve the list of paths within the directory
    set subpaths [glob -nocomplain -directory $path -types d -- *]

    # Now recursively process each directory
    foreach subpath [lsort $subpaths] {

        ProcessPath $subpath
    }
}

proc Usage { } {

    puts "Usage: spp.tcl -i <srcpath> -o <dstpath>"
    puts "Options:"
    puts "  -i, --input     Directory of source file templates"
    puts "  -o, --output    Target directory for generated files"
    puts "  -s, --silent    Enables silent operation"
    puts "  -t, --smacro    Specifies directory of the smacro script"
    puts "  -h, --help      Print this message"
}

proc ParseOptions { argv } {

    global options

    set i 0
    set ok 1

    # Process each command line option
    while { $ok && $i < [llength $argv] } {

        set arg [lindex $argv $i]
        incr i

        switch -- $arg {
            "-i" -
            "--input" {
                set options(Input) [lindex $argv $i]
                incr i
            }
            "-o" -
            "--output" {
                set options(Output) [lindex $argv $i]
                incr i
            }
            "-s" -
            "--silent" {
                set options(Verbose) 0
            }
            "-t" -
            "--smacro" {
                set options(ScriptDir) [lindex $argv $i]
                incr i
            }
            "-h" -
            "--help" {
                Usage
                set ok 0
            }
            default {
                PrintError "Unknown option: $arg"
                set ok 0
            }
        }
    }

    # Default the script directory
    if { $ok && $options(ScriptDir) == "" } {

        set options(ScriptDir) [pwd]
    }

    # Validate the root path
    if { $ok && $options(Input) != "" && [file exists $options(Input)] == 0 } {

        PrintError "Input path does not exist \"$options(Input)\""
        set ok 0
    }

    # Normalize the output path
    set options(Output) [file normalize $options(Output)]

    # Validate the smacro script file
    set options(ScriptFile) [file normalize [file join $options(ScriptDir) $options(ScriptName)]]
    if { $ok && [file exists $options(ScriptFile)] == 0 } {

        PrintError "Failed to find $options(ScriptName)"
        set ok 0
    }

    return $ok
}

proc Main { argv } {

    global options

    # Parse the command line options
    set ok [ParseOptions $argv]

    if { $ok } {

        uplevel source "$options(ScriptFile)"

        set cwd [pwd]
        if { $options(Input) != "" } { cd $options(Input) }

        # Start processing the root directory
        ProcessPath ""

        cd $cwd
    }

    return $ok
}

if { [Main $argv] } {
    exit 0
}

exit 1

