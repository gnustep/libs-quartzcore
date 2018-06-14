
ifeq ($(GNUSTEP_MAKEFILES),)
  GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(error You need to set GNUSTEP_MAKEFILES before compiling!)
  endif
endif

include $(GNUSTEP_MAKEFILES)/common.make
#
# Main framework
#
FRAMEWORK_NAME =CAAppKitBridge

# Include configuration

-include ../config.make

CAAppKitBridge_OBJCFLAGS += -std=c99
#CAAppKitBridge_HEADER_FILES_DIR = ../Headers/CAAppKitBridge
#CAAppKitBridge_HEADER_FILES = \
#	CAData.h \
#   NSView+CAmethods.h

CAAppKitBridge_OBJC_FILES = $(wildcard *.m)

CAAppKitBridge_OBJCFLAGS += $(WARN_FLAGS)
# Treat warnings as errors unless someone chooses to ignore them.
#ifneq ($(nonstrict), yes)
#QuartzCore_OBJCFLAGS += -Werror
#endif

-include ../GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/framework.make

-include GNUmakefile.postamble
