include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = QuartzCoreDemo

QuartzCoreDemo_OBJC_FILES = \
	main.m \
	AppController.m \
	DemoOpenGLView.m \
	TextLayer.m \
	GradientLayer.m
	
QuartzCoreDemo_RESOURCE_FILES = \
	GNUstep.tiff \
	GNUstep.png

ADDITIONAL_LDFLAGS += $(shell pkg-config --libs cairo) -L../Source/QuartzCore.framework

ADDITIONAL_OBJCFLAGS += -Wall -g -O0 -std=gnu99
ADDITIONAL_CFLAGS += -Wall -g -O0 -std=gnu99
ADDITIONAL_TOOL_LIBS =  -lgnustep-gui -lGL -lGLU -lopal -lQuartzCore 
ADDITIONAL_INCLUDE_DIRS = -I../Headers

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
