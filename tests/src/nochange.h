#ifndef NOCHANGE_H
#define NOCHANGE_H

namespace test
{
#tcl set value1 "this has no output"

struct TestStruct
{
    int Value;
};
#tcl \
set value2 "this has no output" \
set value3 "this has no output"

}

#endif // NOCHANGE_H
