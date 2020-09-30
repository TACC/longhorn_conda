#!/bin/bash

set -ex

mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} \
	-DSPM_BUILD_TEST=ON \
	..
make -j 8
make test
make install

cd ../python

$PYTHON setup.py build
$PYTHON setup.py install
