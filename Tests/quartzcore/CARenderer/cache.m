/* A layer with shouldRasterize is drawn into an offscreen buffer.  CARenderer
   reuses that buffer until the layer or one of its sublayers changes, so a
   frame identical to the one before it redraws neither the subtree nor the
   two shadow blur passes.

   The renderer here is built from an NSOpenGLContext where Apple builds one
   from a CGL context, so this file is not run against Apple.

   Building a renderer makes its context current, and a context with nothing
   to draw into never returns from that, so the context is checked before it
   is touched and the set skipped rather than left to hang. */
#import <Foundation/Foundation.h>
#include "Testing.h"

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

/* CABackingStore.h is not installed, so the two accessors are declared
   here. */
@interface CALayer (RasterizedTexture)
- (id) backingStore;
@end

@interface NSObject (RasterizedTexture)
- (id) offscreenRenderTexture;
@end

/* The texture a layer was last rasterised into.  Retained: an address freed
   between frames could otherwise be reallocated and compare equal. */
static id rasterizedTexture(CALayer *layer)
{
  return [[[[layer presentationLayer] backingStore]
            offscreenRenderTexture] retain];
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

  START_SET("reuse of a rasterised layer's texture")

  const char *why = "";
  NSOpenGLContext *context = usableContext(&why);
  CARenderer *renderer;
  id first, unchanged, redisplayed, stillRedisplayed, again, moved;

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

  CALayer *root = [CALayer layer];
  CALayer *rasterised = [CALayer layer];
  CALayer *sublayer = [CALayer layer];

  [root setBounds: CGRectMake(0, 0, VIEW_W, VIEW_H)];
  [root setPosition: CGPointMake(VIEW_W / 2.0, VIEW_H / 2.0)];
  [rasterised setBounds: CGRectMake(0, 0, 40, 30)];
  [rasterised setPosition: CGPointMake(VIEW_W / 2.0, VIEW_H / 2.0)];
  [rasterised setShouldRasterize: YES];
  [sublayer setBounds: CGRectMake(0, 0, 20, 20)];
  [sublayer setPosition: CGPointMake(10, 15)];
  [sublayer setBackgroundColor: blue];
  [rasterised addSublayer: sublayer];
  [root addSublayer: rasterised];

  [CATransaction commit];

  renderFrame(renderer, root);
  first = rasterizedTexture(rasterised);
  PASS(first != nil, "a rasterised layer is drawn into a texture");

  renderFrame(renderer, root);
  unchanged = rasterizedTexture(rasterised);
  PASS(unchanged == first, "an unchanged frame reuses that texture");

  [rasterised setNeedsDisplay];
  renderFrame(renderer, root);
  redisplayed = rasterizedTexture(rasterised);
  PASS(redisplayed != first, "-setNeedsDisplay rasterises the layer again");

  renderFrame(renderer, root);
  stillRedisplayed = rasterizedTexture(rasterised);
  PASS(stillRedisplayed == redisplayed,
       "and the next unchanged frame reuses the new texture");

  [rasterised setNeedsDisplay];
  renderFrame(renderer, root);
  again = rasterizedTexture(rasterised);
  PASS(again != redisplayed,
       "a second -setNeedsDisplay rasterises it again");

  [CATransaction begin];
  [CATransaction setDisableActions: YES];
  [sublayer setPosition: CGPointMake(30, 15)];
  [CATransaction commit];
  renderFrame(renderer, root);
  moved = rasterizedTexture(rasterised);
  PASS(moved != again, "moving a sublayer rasterises it again");

  [first release];
  [unchanged release];
  [redisplayed release];
  [stillRedisplayed release];
  [again release];
  [moved release];
  CGColorRelease(blue);

  END_SET("reuse of a rasterised layer's texture")

  [pool release];
  return 0;
}
