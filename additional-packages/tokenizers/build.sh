#!/bin/bash

cd bindings/python

$PYTHON setup.py install --single-version-externally-managed --record record.txt

exit 0
