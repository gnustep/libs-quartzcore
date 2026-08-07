/* A layer with a shadow is blurred into an offscreen buffer and that buffer is
   drawn behind it, offset.  The buffer has to be the size of what it holds:
   a fixed size draws the shadow as a quad of that size whatever the layer
   covers, which for a small layer paints the whole drawable.

   The renderer here is built from an NSOpenGLContext where Apple builds one
   from a CGL context, so this file is not run against Apple. */
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

static BOOL changedAt(const unsigned char *before, const unsigned char *after,
                      int x, int y)
{
  long o = (y * drawableW + x) * 4;

  return memcmp(before + o, after + o, 4) != 0;
}

static int changedCount(const unsigned char *before, const unsigned char *after)
{
  int x, y, count = 0;

  for (y = 0; y < drawableH; y++)
    for (x = 0; x < drawableW; x++)
      if (changedAt(before, after, x, y))
        count++;
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

/* A layer of the given size in the middle of the drawable, with a colour of
   its own, shadowed or not, and with a shadow of the given shape or of its
   own. */
static CALayer *shaped(BOOL withShadow, CGColorRef fill, CGColorRef shade,
                       CGPathRef path)
{
  CALayer *root = [CALayer layer];
  CALayer *layer = [CALayer layer];

  [root setBounds: CGRectMake(0, 0, VIEW_W, VIEW_H)];
  [root setPosition: CGPointMake(VIEW_W / 2.0, VIEW_H / 2.0)];

  [layer setBounds: CGRectMake(0, 0, 20, 14)];
  [layer setPosition: CGPointMake(VIEW_W / 2.0, VIEW_H / 2.0)];
  [layer setBackgroundColor: fill];
  if (withShadow)
    {
      [layer setShadowColor: shade];
      [layer setShadowOpacity: 1.0];
      [layer setShadowOffset: CGSizeMake(6, -6)];
      [layer setShadowRadius: 2];
      [layer setShadowPath: path];
    }
  [root addSublayer: layer];
  return root;
}

static CALayer *shadowed(BOOL withShadow, CGColorRef fill, CGColorRef shade)
{
  return shaped(withShadow, fill, shade, NULL);
}

/* A rectangle in the layer's own coordinate space, the layer's bounds being
   0, 0, 20, 14. */
static CGPathRef rectPath(CGRect r)
{
  CGMutablePathRef path = CGPathCreateMutable();

  CGPathAddRect(path, NULL, r);
  return path;
}

/* The mean row of the pixels that differ, which says where the shadow ended
   up without depending on which way round the rows run. */
static double meanChangedRow(const unsigned char *before,
                             const unsigned char *after)
{
  int x, y, count = 0;
  double total = 0;

  for (y = 0; y < drawableH; y++)
    for (x = 0; x < drawableW; x++)
      if (changedAt(before, after, x, y))
        {
          total += y;
          count++;
        }
  return count ? total / count : -1;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("where a shadow is drawn")

  const char *why = "";
  NSOpenGLContext *context = usableContext(&why);
  CARenderer *renderer;
  static unsigned char plain[MAX_PIXELS];
  static unsigned char shaded[MAX_PIXELS];
  int changed;

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

  /* The drawable is cleared to black and does not read back transparent, so
     the shadow is given a colour of its own to be seen by. */
  CGColorRef white = CGColorCreateGenericRGB(1, 1, 1, 1);
  CGColorRef red = CGColorCreateGenericRGB(1, 0, 0, 1);
  CALayer *bare = shadowed(NO, white, red);
  CALayer *withShadow = shadowed(YES, white, red);

  [CATransaction commit];

  renderFrame(renderer, bare);
  readDrawable(plain);

  renderFrame(renderer, withShadow);
  readDrawable(shaded);

  changed = changedCount(plain, shaded);
  PASS(changed > 0, "a shadow paints something the layer alone does not");
  PASS(!changedAt(plain, shaded, 1, drawableH - 2)
       && !changedAt(plain, shaded, drawableW - 2, drawableH - 2),
       "and leaves the far corners of the drawable alone");

  /* A shadowPath is the shape of the shadow, in place of the layer's own
     outline, so a path smaller than the layer casts less and one larger than
     the layer casts more. */
  {
    static unsigned char small[MAX_PIXELS];
    static unsigned char large[MAX_PIXELS];
    static unsigned char high[MAX_PIXELS];
    static unsigned char low[MAX_PIXELS];
    CGPathRef middle = rectPath(CGRectMake(7, 5, 6, 4));
    CGPathRef around = rectPath(CGRectMake(-6, -6, 32, 26));
    CGPathRef top = rectPath(CGRectMake(2, 8, 16, 4));
    CGPathRef bottom = rectPath(CGRectMake(2, 2, 16, 4));

    [CATransaction begin];
    [CATransaction setDisableActions: YES];
    CALayer *smallShadow = shaped(YES, white, red, middle);
    CALayer *largeShadow = shaped(YES, white, red, around);
    CALayer *highShadow = shaped(YES, white, red, top);
    CALayer *lowShadow = shaped(YES, white, red, bottom);
    [CATransaction commit];

    renderFrame(renderer, smallShadow);
    readDrawable(small);
    renderFrame(renderer, largeShadow);
    readDrawable(large);
    renderFrame(renderer, highShadow);
    readDrawable(high);
    renderFrame(renderer, lowShadow);
    readDrawable(low);

    PASS(changedCount(plain, small) < changed,
         "a shadowPath smaller than the layer casts a smaller shadow");
    PASS(changedCount(plain, large) > changed,
         "and one larger than the layer casts a larger shadow");
    PASS(meanChangedRow(plain, high) > meanChangedRow(plain, low),
         "a shadowPath high in the layer casts its shadow high");

    CGPathRelease(middle);
    CGPathRelease(around);
    CGPathRelease(top);
    CGPathRelease(bottom);
  }

  CGColorRelease(white);
  CGColorRelease(red);

  END_SET("where a shadow is drawn")

  [pool release];
  return 0;
}
