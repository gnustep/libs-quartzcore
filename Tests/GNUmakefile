include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = hello hello_opal

main_files = main.m QCTestOpenGLView.m

hello_OBJC_FILES = $(main_files) hello.m

hello_opal_OBJC_FILES = $(main_files) hello_opal.m
hello_opal_LIBS = -lopal

# Some examples from opal:
#TOOL_NAME = test1 test2 test3

#ifeq ($(GNUSTEP_TARGET_OS), mingw32)
#main_file = win32.m
#else
#main_file = x11.m
#endif

#shapes_OBJC_FILES = $(main_file) arcs.m ovals.m rects.m shapes.m
#textlayout_OBJC_FILES = $(main_file) textlayout.m
#pdf_OBJC_FILES = pdf.m arcs.m ovals.m rects.m
#images_OBJC_FILES = $(main_file) images.m
#images_RESOURCE_FILES = test.png test.jpg


#ifneq ($(GNUSTEP_TARGET_OS), mingw32)
#ADDITIONAL_LDFLAGS += -lm 
#else
#ADDITIONAL_LDFLAGS += -lgdi32
#endif

ADDITIONAL_OBJCFLAGS += -Wall -g -O0 -std=gnu99
ADDITIONAL_CFLAGS += -Wall -g -O0 -std=gnu99
ADDITIONAL_LDFLAGS += -L../Source/obj 
ADDITIONAL_TOOL_LIBS =  -lgnustep-gui -lGL -lGLU -lcairo -lopal
#-lquartzcore
ADDITIONAL_INCLUDE_DIRS = -I../Headers

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
