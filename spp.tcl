#!/usr/bin/env tclsh
#
#-----------------------------------------
# Copyright (C) 2011 by Hart Codeworks Ltd
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#--------------
#
# Written by Francis Hart.
#
# TCL script that finds and processes source file templates that have
# embedded TCL code blocks.

set options(Input)      ""
set options(Output)     "output"
set options(Copy)       0
set options(Verbose)    1
set options(Force)      0
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
        ".xml" -
        ".htm" -
        ".html" -
        ".php" {
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

    } elseif { $options(Copy) } {

        # Just copy it across

        set copy 0

        # Copy if the force flag is set
        if { $options(Force) } {

            set copy 1

        } else {

            # Copy if the destination file does not yet exist
            if { [file exists $dstFile] == 0 } {

                set copy 1

            } else {

                set srcSize [file size $filename]
                set dstSize [file size $dstFile]

                # Copy if there is a size mismatch
                if { $srcSize != $dstSize } {

                    set copy 1

                } else {

                    set srcTime [file mtime $filename]
                    set dstTime [file mtime $dstFile]

                    # Copy if the modification time is newer
                    if { $dstTime < $srcTime } {

                        set copy 1
                    }
                }
            }
        }

        if { $copy } {

            PrintMessage "Copying:    $filename"
            file copy -force -- $filename $dstFile
        }
    }
}

proc ProcessPath { path } {

    global options

    # Find files in this directory
    set files [glob -nocomplain -directory $path -types f hidden -- .* *]

    # Now process each file
    foreach file [lsort $files] {

        ProcessFile $file
    }

    # Retrieve the list of paths within the directory
    set subpaths [glob -nocomplain -directory $path -types d hidden -- *]

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
    puts "  -c, --copy      Copy across plain files as well as processed files"
    puts "  -s, --silent    Enables silent operation"
    puts "  -t, --smacro    Specifies directory of the smacro script"
    puts "  -f, --force     Turn off timestamp check when copying files"
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
            "-c" -
            "--copy" {
                set options(Copy) 1
                incr i
            }
            "-s" -
            "--silent" {
                set options(Verbose) 0
            }
            "-f" -
            "--force" {
                set options(Force) 1
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

    return 0
}

return 1
