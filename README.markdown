Smacro
======
Smacro is a tool for programmatically generating embedded content within a file. It is similar in concept to the C/C++ preprocessor macro, except that the embedded code is expressed in TCL, allowing a far richer set of possibilities for content generation. The tool reads an input file and searches for the embedded TCL code. It extracts this code, runs it through a TCL interpreter, and replaces it with the output from the interpreter.

Input files are not limited to C/C++ source. The embedded TCL code blocks can be placed within any text file, such as xml/html, css, or javascript files.

Embedding Code
--------------
The embedded code must be contained with specific markers within the file. Three types of markers are currently supported.

* C/C++ preprocessor directives
>    `#tcl 'some TCL code'`

* C++ single line comments (compatible with css and javascript)
>    `// tcl 'some TCL code'`

* Xml style comments
>    `<!-- tcl 'some TCL code' -->`

Examples
--------
The are examples of using the tool that show how to process a set of C++ source files, and also how to process a set of html, css, and javascipt files to statically generate a website.

Architecture
------------
The tool consists of a TCL library and two TCL scripts.

The smacro TCL library is contained with the smacro.tcl file. This can be used by external TCL code simply by sourcing it. This file also contains a script when it is run directly from the command line. This takes a single file as input, processes it, and writes a single output file.

The spp.tcl file contains another TCL script that allows the user to recursively find all files in a specific directory, and uses the smacro TCL library to process each file.

License
-------
Smacro is licensed under the MIT license.

Acknowledgements
----------------
Smacro was designed and implemented by Francis Hart for [Hart Codeworks](http://www.hartcw.com).
