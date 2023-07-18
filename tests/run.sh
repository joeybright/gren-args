#!/bin/bash

if [ -f "run_tests" ] ; then
    rm run_tests # Remove the existing node tests
fi
gren make src/Main.gren --output run_tests
node run_tests