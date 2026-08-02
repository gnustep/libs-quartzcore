/* What a renderer holds, before anything is drawn with it.

   Expected values checked against Apple QuartzCore, which builds a renderer
   from a CGL context where this builds one from an NSOpenGLContext, so this
   file is not run against it.

   Building a renderer makes its context current, and a context with nothing
   to draw into never returns from that.  So every step below is checked
   before the context is touched, and the set is skipped rather than left to
   hang if any of them does not hold. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <stdlib.h>
#include <string.h>

#import <AppKit/AppKit.h>
#import <QuartzCore/CARenderer.h>
#import <QuartzCore/CALayer.h>

/* Builds a window with a drawable, or answers nil having touched nothing
   that could block.  The reason is written into *why. */
static NSOpenGLContext *
usableContext(const char **why)
{
  NSOpenGLPixelFormatAttribute attrs[] = {
    NSOpenGLPFADoubleBuffer,
    NSOpenGLPFADepthSize, 24,
    0
  };
  NSOpenGLPixelFormat *format;
  NSWindow *window;
  NSOpenGLView *view;
  const char *display = getenv("DISPLAY");
  BOOL started = YES;

  if (display == NULL || *display == '\0')
    {
      *why = "there is no display, so nothing can be drawn into";
      return nil;
    }

  @try
    {
      [NSApplication sharedApplication];
    }
  @catch (NSException *e)
    {
      started = NO;
    }

  if (started == NO || NSApp == nil)
    {
      *why = "the backend would not start";
      return nil;
    }

  format = [[[NSOpenGLPixelFormat alloc]
              initWithAttributes: attrs] autorelease];
  if (format == nil)
    {
      *why = "there is no pixel format to draw with";
      return nil;
    }

  window = [[[NSWindow alloc]
              initWithContentRect: NSMakeRect(0, 0, 64, 48)
                        styleMask: NSBorderlessWindowMask
                          backing: NSBackingStoreBuffered
                            defer: NO] autorelease];
  view = [[[NSOpenGLView alloc] initWithFrame: NSMakeRect(0, 0, 64, 48)
                                  pixelFormat: format] autorelease];
  if (window == nil || view == nil)
    {
      *why = "no window to put a drawable in";
      return nil;
    }

  [window setContentView: view];
  [window orderFront: nil];

  /* The window server has to have given us a real window, or there is
     nothing behind the context to draw into. */
  if ([window windowNumber] <= 0)
    {
      *why = "the window server gave out no window";
      return nil;
    }

  if ([view openGLContext] == nil)
    {
      *why = "the view came back with no context";
      return nil;
    }

  return [view openGLContext];
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what a renderer holds")

  const char *why = "";
  NSOpenGLContext *context = usableContext(&why);
  CARenderer *renderer;
  CALayer *layer;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  renderer = [CARenderer rendererWithNSOpenGLContext: context options: nil];
  PASS(renderer != nil, "a renderer can be built from a context");

  if (renderer == nil)
    {
      SKIP("there is no renderer to ask anything of")
    }

  PASS([renderer layer] == nil, "it starts with no layer");

  layer = [CALayer layer];
  [layer setBounds: CGRectMake(0, 0, 40, 30)];
  [renderer setLayer: layer];
  PASS([renderer layer] == layer, "the layer reads back as it was set");

  [renderer setLayer: nil];
  PASS([renderer layer] == nil, "and can be taken away again");

  [renderer setBounds: CGRectMake(0, 0, 64, 48)];
  PASS(CGRectEqualToRect([renderer bounds], CGRectMake(0, 0, 64, 48)),
       "the bounds read back as they were set");

  PASS_RUNS([renderer addUpdateRect: CGRectMake(0, 0, 10, 10)],
            "a rectangle can be handed to it for updating");

  /* Apple answers a null rectangle here, having been given a layer, bounds
     and an update rectangle: what wants redrawing is worked out during a
     frame rather than kept as the union of what it was told. */
  testHopeful = YES;
  PASS(CGRectIsNull([renderer updateBounds]),
       "what wants updating is nothing until a frame asks");
  testHopeful = NO;

  END_SET("what a renderer holds")

  [pool release];
  return 0;
}
