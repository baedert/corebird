#!/bin/bash

# As long as the CMake vala stuff has no support for GResources,
# this script will just comppile it.

# MUST RUN BEFORE 'make'

glib-compile-resources resources.xml --target=src/resources.c --generate-source 
