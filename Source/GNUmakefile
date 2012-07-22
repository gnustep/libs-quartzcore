
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
FRAMEWORK_NAME = QuartzCore

# Include configuration

-include ../config.make

QuartzCore_OBJCFLAGS += -std=c99
QuartzCore_HEADER_FILES_DIR = ../Headers/QuartzCore
QuartzCore_HEADER_FILES = \
	AppleSupport.h \
	AppleSupportRevert.h \
	CAAction.h \
	CAAnimation.h \
	CABase.h \
	CADisplayLink.h \
	CAEAGLLayer.h \
	CAGradientLayer.h \
	CALayer.h \
	CAMediaTimingFunction.h \
	CAMediaTiming.h \
	CARenderer.h \
	CAReplicatorLayer.h \
	CAScrollLayer.h \
	CAShapeLayer.h \
	CATextLayer.h \
	CATiledLayer.h \
	CATransaction.h \
	CATransform3D.h \
	CATransformLayer.h \
	CAValueFunction.h \
	CoreAnimation.h \
	QuartzCore.h

QuartzCore_OBJC_FILES = $(wildcard *.m) $(wildcard GLHelpers/*.m)

QuartzCore_OBJCFLAGS += $(WARN_FLAGS) 
# Treat warnings as errors unless someone chooses to ignore them.
#ifneq ($(nonstrict), yes)
#QuartzCore_OBJCFLAGS += -Werror
#endif

-include ../GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/framework.make

-include GNUmakefile.postamble
