# Headless regression tests for QuartzCore.
#
# These require a desktop-GL context created without a display, via a
# surfaceless EGL context (Mesa/llvmpipe).  They are therefore only built when
# EGL is available; on platforms without it the target is skipped.
#
# Run with:  make check

include $(GNUSTEP_MAKEFILES)/common.make

HAVE_EGL := $(shell pkg-config --exists egl 2>/dev/null && echo yes)

QC_LIBDIR := $(CURDIR)/../../Source/QuartzCore.framework/Versions/0

ifeq ($(HAVE_EGL),yes)

TOOL_NAME = headless_texture
headless_texture_OBJC_FILES = headless_texture.m

ADDITIONAL_OBJCFLAGS += $(shell pkg-config --cflags egl)
ADDITIONAL_LIB_DIRS  += -L$(QC_LIBDIR)
ADDITIONAL_TOOL_LIBS += -lQuartzCore $(shell pkg-config --libs egl) -lGL -lpthread

endif

include $(GNUSTEP_MAKEFILES)/tool.make

ifeq ($(HAVE_EGL),yes)
check:: all
	@echo "Running headless QuartzCore tests..."
	@LD_LIBRARY_PATH="$(QC_LIBDIR):$(LD_LIBRARY_PATH)" \
	  $(GNUSTEP_OBJ_DIR)/headless_texture
else
check::
	@echo "EGL not found (pkg-config egl); skipping headless QuartzCore tests."
endif
