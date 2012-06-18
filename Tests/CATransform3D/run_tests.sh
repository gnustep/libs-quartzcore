#!/bin/bash

cd ../../
make && sudo -E make install
cd -
make clean && make && ./obj/catransform3d

