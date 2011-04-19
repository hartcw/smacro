#!/usr/bin/env tclsh
exec ../spp.tcl -t ".." -i "src" -o "output" >&@ stdout
set files [glob -directory "src" -types f hidden -- .* *]
foreach src [lsort $files] {
    set name [file tail $src]
    set reference [file join "reference" $name]
    set output [file join "output" $name]
    puts "Comparing: $src"
    exec diff $reference $output
}
