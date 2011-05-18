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
# TCL library and script that expands a source file that has embedded TCL
# code blocks.

package provide smacro

namespace eval ::smacro {

    variable srcName  "stdin"
    variable dstName  "stdout"
    variable srcFile  "stdin"
    variable dstFile  "stdout"
    variable rootPath "."
    variable expType  "cpp"
    variable indent   ""
    variable values
}

proc ::smacro::WriteOutput { dst str } {

    variable indent

    if { $str == "" } {

        puts -nonewline $dst "\n"

    } else {

        foreach line [split $str "\n"] {

            puts -nonewline $dst $indent
            puts -nonewline $dst "${line}\n"
        }
    }
}

proc ::smacro::PrintError { error } {

    puts "ERROR: $error"
}

proc ::smacro::Exists { var } {

    variable values
    return [info exists values($var)]
}

proc ::smacro::SetValue { var value } {

    variable values
    set values($var) $value
}

proc ::smacro::GetValue { var } {

    variable values

    set value ""

    if { [info exists values($var)] } {

        set value $values($var)
    }

    return $value
}

proc ::smacro::GetRootPath { } {

    variable rootPath
    return $rootPath
}

proc ::smacro::GetInputFile { } {

    variable srcName
    return $srcName
}

proc ::smacro::GetOutputFile { } {

    variable dstName
    return $dstName
}

proc ::smacro::GetInputPath { } {

    return [file dirname [GetInputFile]]
}

proc ::smacro::GetOutputPath { } {

    return [file dirname [GetOutputFile]]
}

proc ::smacro::FindFile { filename } {

    set path [GetInputPath]
    return [file join $path $filename]
}

proc ::smacro::ReadAsString { filename } {

    set file [open $filename r]
    set str [read $file]
    close $file
    return $str
}

proc ::smacro::ReadAsStringList { filename } {

    set str [ReadAsString $filename]
    return [split [string trimright $str]]
}

proc ::smacro::ReadAsLineList { filename } {

    set lines [list]
    set file [open $filename r]
    while { [gets $file line] >= 0 } {
        lappend lines $line
    }
    close $file
    return $lines
}

proc ::smacro::ReadAsByteArray { filename } {

    set file [open $filename r]
    fconfigure $file -translation binary -encoding binary

    set ok 1
    set bytes [list]

    while { $ok } {

        set buffer [read $file 1]

        if { [string length $buffer] == 0 } {

            set ok 0

        } else {

            binary scan $buffer "H2" hex
            lappend bytes "0x$hex"
        }
    }

    close $file
    return $bytes
}

proc ::smacro::PrintFile { filename } {

    variable dstFile

    set contents [::smacro::ReadAsString $filename]
    puts -nonewline $dstFile $contents
}

proc ::smacro::IncludeFile { filename } {

    variable dstName
    variable dstFile

    set srcName [file nativename [file normalize $filename]]
    set srcFile [open $srcName r]

    PushContext context $srcName $dstName $srcFile $dstFile ""
    ProcessInternal
    PopContext context

    close $srcFile
}

proc ::smacro::PushContext { contextRef newSrcName newDstName newSrcFile newDstFile newRootPath } {

    upvar contextRef context

    variable srcName
    variable dstName
    variable srcFile
    variable dstFile
    variable rootPath
    variable indent

    set context(SrcName)  $srcName
    set context(DstName)  $dstName
    set context(SrcFile)  $srcFile
    set context(DstFile)  $dstFile
    set context(RootPath) $rootPath
    set context(Indent)   $indent
    set context(Cwd)      [pwd]

    set srcName  $newSrcName
    set dstName  $newDstName
    set srcFile  $newSrcFile
    set dstFile  $newDstFile
    set rootPath $newRootPath

    if { $srcFile != "stdin" } { set rootPath [file dirname $srcName] }
    if { $rootPath != "" } { cd $rootPath }
}

proc ::smacro::PopContext { contextRef } {

    upvar contextRef context

    variable srcName
    variable dstName
    variable srcFile
    variable dstFile
    variable rootPath
    variable indent

    set srcName  $context(SrcName)
    set dstName  $context(DstName)
    set srcFile  $context(SrcFile)
    set dstFile  $context(DstFile)
    set rootPath $context(RootPath)
    set indent   $context(Indent)

    cd $context(Cwd)
}

proc smacro::Expand { interpreter } {

    variable srcFile
    variable dstFile
    variable expType
    variable indent

    if { $expType == "cpp" } {

        while { [gets $srcFile line] >= 0 } {

            if { [regexp {^([ \t]*)#tcl (.*)} $line match indent exp] } {

                set str ""
                set line $exp

                while { $line != "" && [regexp {(.*)\\$} $line match exp] } {

                    append str $exp
                    append str "\n"

                    gets $srcFile line
                }

                append str $line

                $interpreter eval $str

            } else {

                puts $dstFile $line
            }
        }

    } elseif { $expType == "c++" } {

        while { [gets $srcFile line] >= 0 } {

            if { [regexp {^(.*?)// tcl (.*)$} $line match prefix exp] } {

                puts -nonewline $dstFile $prefix

                $interpreter eval $exp

                puts $dstFile ""

            } else {

                puts $dstFile $line
            }
        }

    } else {

        set srcContents ""

        while { [gets $srcFile line] >= 0 } {

            append srcContents "$line\n"
        }

        set srcIndex 0
        set srcLength [string length $srcContents]

        while { $srcIndex < $srcLength } {

            set pattern {(.*?)<!-- tcl[ \t\n](.*?)[ \t\n]-->}

            if { [regexp -start $srcIndex -- $pattern $srcContents match prefix exp] } {

                puts -nonewline $dstFile $prefix
                set srcIndex [expr $srcIndex + [string length $match]]

                $interpreter eval $exp

            } else {

                puts -nonewline $dstFile [string range $srcContents $srcIndex $srcLength]
                set srcIndex $srcLength
            }
        }
    }
}

proc ::smacro::ProcessInternal { } {

    variable srcFile
    variable dstFile
    variable expType
    variable indent

    set interpreter [interp create]

    $interpreter hide puts
    $interpreter alias puts ::smacro::WriteOutput $dstFile

    $interpreter alias ::smacro::PrintError       ::smacro::PrintError
    $interpreter alias ::smacro::FindFile         ::smacro::FindFile
    $interpreter alias ::smacro::Exists           ::smacro::Exists
    $interpreter alias ::smacro::SetValue         ::smacro::SetValue
    $interpreter alias ::smacro::GetValue         ::smacro::GetValue
    $interpreter alias ::smacro::GetInputFile     ::smacro::GetInputFile
    $interpreter alias ::smacro::GetInputPath     ::smacro::GetInputPath
    $interpreter alias ::smacro::GetOutputFile    ::smacro::GetOutputFile
    $interpreter alias ::smacro::GetOutputPath    ::smacro::GetOutputPath
    $interpreter alias ::smacro::ReadAsString     ::smacro::ReadAsString
    $interpreter alias ::smacro::ReadAsByteArray  ::smacro::ReadAsByteArray
    $interpreter alias ::smacro::ReadAsLineList   ::smacro::ReadAsLineList
    $interpreter alias ::smacro::ReadAsStringList ::smacro::ReadAsStringList
    $interpreter alias ::smacro::PrintFile        ::smacro::PrintFile
    $interpreter alias ::smacro::IncludeFile      ::smacro::IncludeFile

    Expand $interpreter

    interp delete $interpreter
}

proc ::smacro::Process { src dst type root } {

    variable expType
    variable values

    set expType $type
    array unset values

    set srcName $src
    set dstName $dst
    set srcFile "stdin"
    set dstFile "stdout"
    set rootPath $root

    if { $srcName != "stdin" } {
        set srcName [file nativename [file normalize $srcName]]
        set srcFile [open $srcName r]
    }

    if { $dstName != "stdout" } {
        set dstName [file nativename [file normalize $dstName]]
        set dstFile [open $dstName [list WRONLY BINARY CREAT TRUNC]]
    }

    if { $rootPath != "" } {
        set rootPath [file nativename [file normalize $rootPath]]
    }

    PushContext context $srcName $dstName $srcFile $dstFile $rootPath
    ProcessInternal
    PopContext context

    if { $srcName != "stdin" } { close $srcFile }
    if { $dstName != "stdout" } { close $dstFile }
}

proc ::smacro::Usage { } {

    puts {Usage: smacro.tcl -i <inputfile> -o <outputfile>}
    puts {Options:}
    puts {  -i, --input <file>          Specify the input file (defaults to stdin)}
    puts {  -o, --output <file>         Specify the output file (defaults to stdout)}
    puts {  -r, --root <path>           Specify the root directory for execution of the script}
    puts {  -t, --type [cpp|c++|xml]    Set the type of embedded comment to match and expand}
    puts {  -h, --help                  Print this message}
}

proc ::smacro::ParseOptions { argv optionsRef } {

    upvar optionsRef options

    set i 0
    set ok 1

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
            "-r" -
            "--root" {
                set options(Root) [lindex $argv $i]
                incr i
            }
            "-t" -
            "--type" {
                set options(ExpType) [lindex $argv $i]
                incr i
            }
            "-h" -
            "--help" {
                Usage
                set ok 0
            }
            default {
                puts "ERROR: Unknown option: $arg"
                set ok 0
            }
        }
    }

    # Validate the expression match type
    if { $ok && $options(ExpType) != "cpp" && $options(ExpType) != "c++"  && $options(ExpType) != "xml"} {

        PrintError "Invalid expression match type \"$options(ExpType)\""
        set ok 0
    }


    return $ok
}

proc ::smacro::Main { argv } {

    set options(Input)   "stdin"
    set options(Output)  "stdout"
    set options(Root)    [pwd]
    set options(ExpType) "cpp"

    set ok [ParseOptions $argv options]

    if { $ok } {

        smacro::Process $options(Input) $options(Output) $options(ExpType) $options(Root)
    }

    return $ok
}

if { [info exists argv0] && [file tail $argv0] == "smacro.tcl" } {

    if { [::smacro::Main $argv] } {

        return 0
    }

    return 1
}
