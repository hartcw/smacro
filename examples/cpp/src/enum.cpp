#include "enum.h"
#include <cstring>

#tcl \
set values [smacro::ReadAsStringList "values.txt"]

const char *
ToString(ExampleType type)
{
    static const char *map[] =
    {
        #tcl \
        foreach value $values {        \
            puts "\"EXAMPLE_$value\"," \
        }
        "invalid"
    };

    const char *str = "invalid";

    if (state >= 0 && state < EXAMPLE_Max)
    {
        str = map[type];
    }

    return str;
}

ExampleType
FromString(const char *str)
{
    ExampleType type;

    if (str == NULL)
    {
        type = EXAMPLE_Unknown;
    }
    #tcl \
    foreach value $values {                                                          \
        puts "else if (strcmp(str, \"EXAMPLE_$value\") == 0) type = EXAMPLE_$value;" \
    }

    return type;
}
