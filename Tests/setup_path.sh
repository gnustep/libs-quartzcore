#!/bin/bash
#
# To run tests without installing QuartzCore.framework, 
# 'source' this file, like this:
#   bash$ . setup_path.sh

export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:`pwd`/../Source/QuartzCore.framework/Versions/0/"
