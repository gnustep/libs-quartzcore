include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = CAAppKitBridgeDemo

CAAppKitBridgeDemo_OBJC_FILES = \
	main.m \
	DemoController.m


ADDITIONAL_LDFLAGS += $(shell pkg-config --libs cairo) -L../Source/CAAppKitBridge.framework

ADDITIONAL_OBJCFLAGS += -Wall -g -O0 -std=gnu99
ADDITIONAL_CFLAGS += -Wall -g -O0 -std=gnu99
ADDITIONAL_TOOL_LIBS =  -lgnustep-gui -lGL -lGLU -lopal -lQuartzCore -lCAAppKitBridge

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble
