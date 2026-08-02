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

  START_SET("a renderer that has been given nothing")

  const char *whyEmpty = "";
  NSOpenGLContext *emptyContext = usableContext(&whyEmpty);
  CARenderer *empty;

  if (emptyContext == nil)
    {
      SKIP("%s", whyEmpty)
    }

  empty = [CARenderer rendererWithNSOpenGLContext: emptyContext options: nil];
  if (empty == nil)
    {
      SKIP("there is no renderer to ask anything of")
    }

  testHopeful = YES;
  PASS(CGRectIsNull([empty bounds]), "it has no bounds until given some");
  PASS(isinf([empty nextFrameTime]), "and nothing is due to be drawn");
  testHopeful = NO;

  END_SET("a renderer that has been given nothing")

  START_SET("beginning and ending a frame")

  const char *whyFrame = "";
  NSOpenGLContext *frameContext = usableContext(&whyFrame);
  CARenderer *framed;
  CALayer *framedLayer;

  if (frameContext == nil)
    {
      SKIP("%s", whyFrame)
    }

  framed = [CARenderer rendererWithNSOpenGLContext: frameContext options: nil];
  if (framed == nil)
    {
      SKIP("there is no renderer to ask anything of")
    }

  framedLayer = [CALayer layer];
  [framedLayer setBounds: CGRectMake(0, 0, 40, 30)];
  [framed setLayer: framedLayer];
  [framed setBounds: CGRectMake(0, 0, 64, 48)];

  PASS_RUNS([framed beginFrameAtTime: 0.0 timeStamp: NULL],
            "a frame can be begun");
  PASS_RUNS([framed endFrame], "and ended");
  PASS_RUNS([framed beginFrameAtTime: 1.0 timeStamp: NULL];
            [framed endFrame],
            "and another begun and ended after it");

  /* What nextFrameTime answers once a frame has run is left alone here.
     Giving the layer its bounds asks for an implicit animation, and
     beginning a frame commits the transaction holding it, so the layer is
     genuinely animating by this point.  Apple answers infinity either way,
     which may only mean its renderer schedules nothing when it has no
     display to drive, so there is nothing here worth pinning. */

  PASS_RUNS([framed endFrame],
            "ending a frame that was never begun does nothing");

  END_SET("beginning and ending a frame")

  [pool release];
  return 0;
}
