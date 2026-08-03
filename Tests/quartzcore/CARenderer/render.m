/* What -render puts on the screen, and what it leaves GL in.

   A renderer here is built from an NSOpenGLContext where Apple builds one
   from a CGL context, so this cannot be run against Apple and the file is
   named in APPLE_SKIP_TESTS.

   Building a renderer makes its context current, and a context with nothing
   to draw into never returns from that.  So every step below is checked
   before the context is touched, and the set is skipped rather than left to
   hang if any of them does not hold. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <stdlib.h>

#import <AppKit/AppKit.h>
#define GL_GLEXT_PROTOTYPES 1
#import <GL/gl.h>
#import <GL/glext.h>
#import <QuartzCore/CABase.h>
#import <QuartzCore/CARenderer.h>
#import <QuartzCore/CALayer.h>
#import <QuartzCore/CATransaction.h>

#define WIDTH 64
#define HEIGHT 48

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
              initWithContentRect: NSMakeRect(0, 0, WIDTH, HEIGHT)
                        styleMask: NSBorderlessWindowMask
                          backing: NSBackingStoreBuffered
                            defer: NO] autorelease];
  view = [[[NSOpenGLView alloc] initWithFrame: NSMakeRect(0, 0, WIDTH, HEIGHT)
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

static void clearErrors(void)
{
  while (glGetError() != GL_NO_ERROR)
    {
    }
}

/* Paints the whole drawable so that anything the renderer puts down can be
   told apart from what was there before. */
static void clearToBlue(void)
{
  glClearColor(0.0, 0.0, 1.0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

static BOOL pixelIs(int x, int y, int r, int g, int b)
{
  unsigned char px[4] = { 0, 0, 0, 0 };

  glReadBuffer(GL_BACK);
  glReadPixels(x, y, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, px);
  return px[0] == r && px[1] == g && px[2] == b;
}

static CGColorRef opaqueColor(CGColorSpaceRef space, CGFloat r, CGFloat g, CGFloat b)
{
  CGFloat components[4];

  components[0] = r;
  components[1] = g;
  components[2] = b;
  components[3] = 1.0;
  return CGColorCreate(space, components);
}

/* Runs one frame through the renderer. */
static void renderFrame(CARenderer *renderer)
{
  [renderer beginFrameAtTime: CACurrentMediaTime() timeStamp: NULL];
  [renderer render];
  [renderer endFrame];
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  const char *why = "";
  NSOpenGLContext *context = usableContext(&why);
  CGColorSpaceRef space = NULL;

  if (context != nil)
    {
      [context makeCurrentContext];
      space = CGColorSpaceCreateDeviceRGB();
    }

  START_SET("rendering a layer")

  CARenderer *renderer;
  CALayer *layer;
  CGColorRef red;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  clearErrors();

  /* Setting a layer up outside a transaction starts an implicit animation
     for every property, and the frame would show where each one began. */
  [CATransaction begin];
  [CATransaction setDisableActions: YES];

  renderer = [CARenderer rendererWithNSOpenGLContext: context options: nil];
  if (renderer == nil)
    {
      SKIP("there is no renderer to draw with")
    }

  [renderer setBounds: CGRectMake(0, 0, WIDTH, HEIGHT)];

  red = opaqueColor(space, 1.0, 0.0, 0.0);
  layer = [CALayer layer];
  [layer setBounds: CGRectMake(0, 0, WIDTH, HEIGHT)];
  [layer setPosition: CGPointMake(WIDTH / 2, HEIGHT / 2)];
  [layer setBackgroundColor: red];
  [renderer setLayer: layer];

  [CATransaction commit];

  clearToBlue();
  PASS(pixelIs(WIDTH / 2, HEIGHT / 2, 0, 0, 255),
       "the drawable starts as it was cleared");

  clearErrors();
  renderFrame(renderer);

  PASS(pixelIs(WIDTH / 2, HEIGHT / 2, 255, 0, 0),
       "a layer that covers the renderer paints its background colour");
  PASS(glGetError() == GL_NO_ERROR, "rendering leaves no error behind");

  CGColorRelease(red);

  END_SET("rendering a layer")

  START_SET("rendering only where the layer is")

  CARenderer *renderer;
  CALayer *layer;
  CGColorRef red;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  clearErrors();

  /* Setting a layer up outside a transaction starts an implicit animation
     for every property, and the frame would show where each one began. */
  [CATransaction begin];
  [CATransaction setDisableActions: YES];

  renderer = [CARenderer rendererWithNSOpenGLContext: context options: nil];
  if (renderer == nil)
    {
      SKIP("there is no renderer to draw with")
    }

  [renderer setBounds: CGRectMake(0, 0, WIDTH, HEIGHT)];

  /* A layer over the lower left quarter of the drawable. */
  red = opaqueColor(space, 1.0, 0.0, 0.0);
  layer = [CALayer layer];
  [layer setBounds: CGRectMake(0, 0, WIDTH / 2, HEIGHT / 2)];
  [layer setPosition: CGPointMake(WIDTH / 4, HEIGHT / 4)];
  [layer setBackgroundColor: red];
  [renderer setLayer: layer];

  [CATransaction commit];

  clearToBlue();
  renderFrame(renderer);

  /* Nothing sets a projection or a viewport, so the vertices, which are in
     points, are taken as normalised device coordinates.  Where a layer lands
     has nothing to do with where it was put. */
  testHopeful = YES;
  PASS(pixelIs(WIDTH / 4, HEIGHT / 4, 255, 0, 0),
       "the layer is painted where it sits");
  PASS(pixelIs(WIDTH * 3 / 4, HEIGHT * 3 / 4, 0, 0, 255),
       "and nothing is painted where it does not");
  testHopeful = NO;

  CGColorRelease(red);

  END_SET("rendering only where the layer is")

  START_SET("rendering a sublayer")

  CARenderer *renderer;
  CALayer *layer;
  CALayer *sublayer;
  CGColorRef red;
  CGColorRef green;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  clearErrors();

  /* Setting a layer up outside a transaction starts an implicit animation
     for every property, and the frame would show where each one began. */
  [CATransaction begin];
  [CATransaction setDisableActions: YES];

  renderer = [CARenderer rendererWithNSOpenGLContext: context options: nil];
  if (renderer == nil)
    {
      SKIP("there is no renderer to draw with")
    }

  [renderer setBounds: CGRectMake(0, 0, WIDTH, HEIGHT)];

  red = opaqueColor(space, 1.0, 0.0, 0.0);
  green = opaqueColor(space, 0.0, 1.0, 0.0);

  layer = [CALayer layer];
  [layer setBounds: CGRectMake(0, 0, WIDTH, HEIGHT)];
  [layer setPosition: CGPointMake(WIDTH / 2, HEIGHT / 2)];
  [layer setBackgroundColor: red];

  sublayer = [CALayer layer];
  [sublayer setBounds: CGRectMake(0, 0, WIDTH / 2, HEIGHT / 2)];
  [sublayer setPosition: CGPointMake(WIDTH / 4, HEIGHT / 4)];
  [sublayer setBackgroundColor: green];
  [layer addSublayer: sublayer];

  [renderer setLayer: layer];

  [CATransaction commit];

  clearToBlue();
  renderFrame(renderer);

  /* A sublayer is drawn relative to the corner of its superlayer, which is a
     translation of half its size.  Taken as normalised device coordinates
     that puts the sublayer somewhere else entirely, and the superlayer is
     the wrong size to be beside it. */
  testHopeful = YES;
  PASS(pixelIs(WIDTH / 4, HEIGHT / 4, 0, 255, 0),
       "a sublayer is painted over its superlayer");
  PASS(pixelIs(WIDTH * 3 / 4, HEIGHT * 3 / 4, 255, 0, 0),
       "and the superlayer is still there beside it");
  testHopeful = NO;

  CGColorRelease(red);
  CGColorRelease(green);

  END_SET("rendering a sublayer")

  START_SET("the state rendering leaves behind")

  CARenderer *renderer;
  CALayer *layer;
  CGColorRef red;
  GLint mode = 0;
  GLint source = 0;
  GLint destination = 0;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  clearErrors();

  /* Setting a layer up outside a transaction starts an implicit animation
     for every property, and the frame would show where each one began. */
  [CATransaction begin];
  [CATransaction setDisableActions: YES];

  renderer = [CARenderer rendererWithNSOpenGLContext: context options: nil];
  if (renderer == nil)
    {
      SKIP("there is no renderer to draw with")
    }

  [renderer setBounds: CGRectMake(0, 0, WIDTH, HEIGHT)];

  red = opaqueColor(space, 1.0, 0.0, 0.0);
  layer = [CALayer layer];
  [layer setBounds: CGRectMake(0, 0, WIDTH, HEIGHT)];
  [layer setPosition: CGPointMake(WIDTH / 2, HEIGHT / 2)];
  [layer setBackgroundColor: red];
  [renderer setLayer: layer];

  [CATransaction commit];

  clearToBlue();
  renderFrame(renderer);

  glGetIntegerv(GL_MATRIX_MODE, &mode);
  glGetIntegerv(GL_BLEND_SRC, &source);
  glGetIntegerv(GL_BLEND_DST, &destination);

  PASS(mode == GL_MODELVIEW, "the matrix mode is put back");
  PASS(glIsEnabled(GL_BLEND) == GL_FALSE, "blending is turned off again");
  PASS(source == GL_ONE && destination == GL_ZERO,
       "and the blend function is put back");
  PASS(glIsEnabled(GL_VERTEX_ARRAY) == GL_FALSE &&
       glIsEnabled(GL_COLOR_ARRAY) == GL_FALSE &&
       glIsEnabled(GL_TEXTURE_COORD_ARRAY) == GL_FALSE,
       "the arrays it turned on are turned off again");

  CGColorRelease(red);

  END_SET("the state rendering leaves behind")

  START_SET("rendering with no layer")

  CARenderer *renderer;

  if (context == nil)
    {
      SKIP("%s", why)
    }

  clearErrors();

  /* Setting a layer up outside a transaction starts an implicit animation
     for every property, and the frame would show where each one began. */
  [CATransaction begin];
  [CATransaction setDisableActions: YES];

  renderer = [CARenderer rendererWithNSOpenGLContext: context options: nil];
  if (renderer == nil)
    {
      SKIP("there is no renderer to draw with")
    }

  [renderer setBounds: CGRectMake(0, 0, WIDTH, HEIGHT)];
  [CATransaction commit];

  clearToBlue();
  renderFrame(renderer);

  PASS(pixelIs(WIDTH / 2, HEIGHT / 2, 0, 0, 255),
       "a renderer with no layer paints nothing");
  PASS(glGetError() == GL_NO_ERROR, "and leaves no error behind");

  END_SET("rendering with no layer")

  if (space != NULL)
    {
      CGColorSpaceRelease(space);
    }
  [pool release];
  return 0;
}
