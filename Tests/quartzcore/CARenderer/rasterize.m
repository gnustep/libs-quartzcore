/* A layer with shouldRasterize is drawn into an offscreen buffer first and
   then composited from it.  That buffer has to cover the layer and everything
   under it: a fixed size crops whatever reaches past it, and a sublayer far
   from its superlayer disappears.

   The renderer here is built from an NSOpenGLContext where Apple builds one
   from a CGL context, so this file is not run against Apple.

   Building a renderer makes its context current, and a context with nothing
   to draw into never returns from that, so the context is checked before it
   is touched and the set skipped rather than left to hang. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <stdlib.h>
#include <string.h>

#import <AppKit/AppKit.h>
#import <QuartzCore/CARenderer.h>
#import <QuartzCore/CALayer.h>
#import <QuartzCore/CATransaction.h>
#ifdef __APPLE__
#include <OpenGL/gl.h>
#else
#include <GL/gl.h>
#endif

#define VIEW_W 64
#define VIEW_H 48
#define MAX_PIXELS (1024 * 1024 * 4)

static int drawableW = VIEW_W;
static int drawableH = VIEW_H;

/* Read the drawable back, taking its size from the viewport rather than from
   the size the window was asked for. */
static void readDrawable(unsigned char *into)
{
  GLint viewport[4] = { 0, 0, VIEW_W, VIEW_H };

  glFinish();
  glGetIntegerv(GL_VIEWPORT, viewport);
  drawableW = viewport[2] > 0 ? viewport[2] : VIEW_W;
  drawableH = viewport[3] > 0 ? viewport[3] : VIEW_H;
  if (drawableW * drawableH * 4 > MAX_PIXELS)
    {
      drawableW = VIEW_W;
      drawableH = VIEW_H;
    }
  memset(into, 0, drawableW * drawableH * 4);
  glReadPixels(0, 0, drawableW, drawableH, GL_RGBA, GL_UNSIGNED_BYTE, into);
}

/* How many pixels differ between two readings, and where.  Two frames are
   compared rather than one examined for a colour, because a window's drawable
   does not read back transparent where nothing was drawn. */
static int changedCount(const unsigned char *before, const unsigned char *after,
                        int *x0, int *x1)
{
  int x, y, count = 0;

  *x0 = drawableW; *x1 = -1;
  for (y = 0; y < drawableH; y++)
    for (x = 0; x < drawableW; x++)
      {
        long o = (y * drawableW + x) * 4;

        if (memcmp(before + o, after + o, 4) != 0)
          {
            count++;
            if (x < *x0) *x0 = x;
            if (x > *x1) *x1 = x;
          }
      }
  return count;
}

static void renderFrame(CARenderer *renderer, CALayer *layer)
{
  [renderer setLayer: layer];
  [renderer setBounds: CGRectMake(0, 0, VIEW_W, VIEW_H)];
  [renderer addUpdateRect: CGRectMake(0, 0, VIEW_W, VIEW_H)];
  glClearColor(0.0, 0.0, 0.0, 0.0);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  [renderer beginFrameAtTime: 0.0 timeStamp: NULL];
  [renderer render];
  [renderer endFrame];
}

/* Builds a window with a drawable, or answers nil having touched nothing that
   could block.  The reason is written into *why. */
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

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      started = NO;
    }
  NS_ENDHANDLER

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
              initWithContentRect: NSMakeRect(0, 0, VIEW_W, VIEW_H)
                        styleMask: NSBorderlessWindowMask
                          backing: NSBackingStoreBuffered
                            defer: NO] autorelease];
  view = [[[NSOpenGLView alloc]
            initWithFrame: NSMakeRect(0, 0, VIEW_W, VIEW_H)
              pixelFormat: format] autorelease];
  if (window == nil || view == nil)
    {
      *why = "no window to put a drawable in";
      return nil;
    }

  [window setContentView: view];
  [window orderFront: nil];

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

  START_SET("what a rasterised layer keeps")

  const char *why = "";
  NSOpenGLContext *context = usableContext(&why);
  CARenderer *renderer;
  static unsigned char without[MAX_PIXELS];
  static unsigned char with[MAX_PIXELS];
  int changed, x0, x1;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  renderer = [CARenderer rendererWithNSOpenGLContext: context options: nil];
  if (renderer == nil)
    {
      SKIP("there is no renderer to draw with")
    }

  [CATransaction begin];
  [CATransaction setDisableActions: YES];

  CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);

  /* Two trees rather than one changed between frames: a rasterised layer
     keeps the texture it was given, so adding a sublayer to a tree already
     drawn would change nothing whatever the buffer's size.

     The distant sublayer sits 280 points to the right of the layer that holds
     it, and that layer is placed so the sublayer lands in the middle of the
     drawable while the layer itself falls outside it. */
  CALayer *bare = [CALayer layer];
  CALayer *bareRasterised = [CALayer layer];

  [bare setBounds: CGRectMake(0, 0, VIEW_W, VIEW_H)];
  [bare setPosition: CGPointMake(VIEW_W / 2.0, VIEW_H / 2.0)];
  [bareRasterised setBounds: CGRectMake(0, 0, 40, 30)];
  [bareRasterised setPosition: CGPointMake(VIEW_W / 2.0 - 280, VIEW_H / 2.0)];
  [bareRasterised setShouldRasterize: YES];
  [bare addSublayer: bareRasterised];

  CALayer *root = [CALayer layer];
  CALayer *rasterised = [CALayer layer];
  CALayer *distant = [CALayer layer];

  [root setBounds: CGRectMake(0, 0, VIEW_W, VIEW_H)];
  [root setPosition: CGPointMake(VIEW_W / 2.0, VIEW_H / 2.0)];
  [rasterised setBounds: CGRectMake(0, 0, 40, 30)];
  [rasterised setPosition: CGPointMake(VIEW_W / 2.0 - 280, VIEW_H / 2.0)];
  [rasterised setShouldRasterize: YES];
  [distant setBounds: CGRectMake(0, 0, 20, 20)];
  [distant setPosition: CGPointMake(300, 15)];
  [distant setBackgroundColor: blue];
  [rasterised addSublayer: distant];
  [root addSublayer: rasterised];

  [CATransaction commit];

  renderFrame(renderer, bare);
  readDrawable(without);

  renderFrame(renderer, root);
  readDrawable(with);

  changed = changedCount(without, with, &x0, &x1);
  PASS(changed > 0,
       "a sublayer far from the layer that rasterises it is still drawn");
  PASS(changed > 0 && x0 > 20 && x1 < VIEW_W - 20,
       "in the middle of the drawable, where it was placed");

  CGColorRelease(blue);

  END_SET("what a rasterised layer keeps")

  [pool release];
  return 0;
}
