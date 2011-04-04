#ifndef ENUM_H
#define ENUM_H

enum ExampleType
{
    #tcl \
    set values [smacro::ReadAsStringList "values.txt"] \
    foreach value $values {                            \
        puts "EXAMPLE_$value,"                         \
    }
    EXAMPLE_Max,
    EXAMPLE_Unknown
};

ExampleType FromString(const char *str);

const char * ToString(ExampleType type);

#endif // ENUM_H
