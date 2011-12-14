# makefile for QuartzCore
#
#  Copyright (C) 2012 Free Software Foundation, Inc.
#
#  Author: Amr Aboelela
#
#  This file is part of QuartzCore.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; see the file COPYING.LIB.
#  If not, see <http://www.gnu.org/licenses/> or write to the
#  Free Software Foundation, 51 Franklin Street, Fifth Floor,
#  Boston, MA 02110-1301, USA.

ifeq ($(GNUSTEP_MAKEFILES),)
  GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(error You need to set GNUSTEP_MAKEFILES before compiling!)
  endif
endif

GNUSTEP_MAKEFILES=/usr/share/GNUstep/Makefiles

include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = QuartzCore
SUBPROJECTS = Source

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble

