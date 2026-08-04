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
#import <QuartzCore/CATransaction.h>
#ifdef __APPLE__
#include <OpenGL/gl.h>
#else
#include <GL/gl.h>
#endif

#define VIEW_W 64
#define VIEW_H 48
#define MAX_PIXELS (1024 * 1024 * 4)

/* The drawable is not necessarily the size the window was asked for, so the
   area to read back is taken from the viewport rather than assumed. */
static int drawableW = VIEW_W;
static int drawableH = VIEW_H;

/* An opaque image of the given size, for a layer's contents. */
static CGImageRef solidImage(int w, int h)
{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef c = CGBitmapContextCreate(NULL, w, h, 8, w * 4, space,
                                         kCGImageAlphaPremultipliedFirst);
  CGColorRef colour = CGColorCreateGenericRGB(0, 0, 1, 1);
  CGImageRef image;

  CGColorSpaceRelease(space);
  memset(CGBitmapContextGetData(c), 0, w * h * 4);
  CGContextSetFillColorWithColor(c, colour);
  CGContextFillRect(c, CGRectMake(0, 0, w, h));
  image = CGBitmapContextCreateImage(c);
  CGColorRelease(colour);
  CGContextRelease(c);
  return image;
}

/* Read the drawable back into `into`, having measured it first. */
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

/* The box of the pixels that differ between two readings.

   Two frames are compared rather than one frame examined for a colour,
   because a window's drawable does not come back transparent where nothing
   was drawn, and the channel order a texture ends up in on Opal is not the
   one the image was built with.  A difference does not care about either. */
static BOOL changedBox(const unsigned char *before, const unsigned char *after,
                       int *x0, int *y0, int *x1, int *y1, int *count)
{
  int x, y;

  *x0 = drawableW; *y0 = drawableH; *x1 = -1; *y1 = -1; *count = 0;
  for (y = 0; y < drawableH; y++)
    for (x = 0; x < drawableW; x++)
      {
        long o = (y * drawableW + x) * 4;

        if (memcmp(before + o, after + o, 4) != 0)
          {
            (*count)++;
            if (x < *x0) *x0 = x;
            if (y < *y0) *y0 = y;
            if (x > *x1) *x1 = x;
            if (y > *y1) *y1 = y;
          }
      }
  return *x1 >= 0;
}

/* Draw one frame of a renderer holding the given layer. */
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

  START_SET("where the renderer puts the contents")

  const char *whyDraw = "";
  NSOpenGLContext *drawContext = usableContext(&whyDraw);
  CARenderer *drawer;
  CGImageRef image;
  int x0, y0, x1, y1, n;
  static unsigned char empty[MAX_PIXELS];
  static unsigned char drawn[MAX_PIXELS];

  if (drawContext == nil)
    {
      SKIP("%s", whyDraw)
    }

  drawer = [CARenderer rendererWithNSOpenGLContext: drawContext options: nil];
  if (drawer == nil)
    {
      SKIP("there is no renderer to draw with")
    }

  image = solidImage(16, 8);

  /* Giving a layer its geometry asks for an implicit animation, and a frame
     begun afterwards renders the presentation layer part way through it,
     which is not where the layer was put.  These are laid out with actions
     switched off so that what is drawn is what was asked for. */
  [CATransaction begin];
  [CATransaction setDisableActions: YES];

  CALayer *bare = [CALayer layer];
  [bare setBounds: CGRectMake(0, 0, VIEW_W, VIEW_H)];
  [bare setPosition: CGPointMake(VIEW_W / 2.0, VIEW_H / 2.0)];

  CALayer *stretched = [CALayer layer];
  [stretched setBounds: CGRectMake(0, 0, VIEW_W, VIEW_H)];
  [stretched setPosition: CGPointMake(VIEW_W / 2.0, VIEW_H / 2.0)];
  [stretched setContents: (id)image];
  [stretched setContentsGravity: kCAGravityResize];

  CALayer *centred = [CALayer layer];
  [centred setBounds: CGRectMake(0, 0, VIEW_W, VIEW_H)];
  [centred setPosition: CGPointMake(VIEW_W / 2.0, VIEW_H / 2.0)];
  [centred setContents: (id)image];
  [centred setContentsGravity: kCAGravityCenter];

  [CATransaction commit];

  renderFrame(drawer, bare);
  readDrawable(empty);

  /* A point of the layer is this many pixels of the drawable. */
  CGFloat scaleX, scaleY;

  renderFrame(drawer, stretched);
  readDrawable(drawn);
  scaleX = (CGFloat)drawableW / VIEW_W;
  scaleY = (CGFloat)drawableH / VIEW_H;
  PASS(changedBox(empty, drawn, &x0, &y0, &x1, &y1, &n)
       && n == drawableW * drawableH,
       "resize draws the contents over the whole layer");

  renderFrame(drawer, centred);
  readDrawable(drawn);
  changedBox(empty, drawn, &x0, &y0, &x1, &y1, &n);
  PASS(x0 == (int)(24 * scaleX) && x1 == (int)(40 * scaleX) - 1
       && y0 == (int)(20 * scaleY) && y1 == (int)(28 * scaleY) - 1,
       "center leaves them their own size in the middle of it");
  PASS(n == (int)(16 * scaleX) * (int)(8 * scaleY),
       "and paints no more than the contents are");

  CGImageRelease(image);

  END_SET("where the renderer puts the contents")

  [pool release];
  return 0;
}
