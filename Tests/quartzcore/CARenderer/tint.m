/* Drawing a layer offscreen and compositing the result is meant to leave it
   looking the same.  The renderer passes a colour of 0.4, 1, 1 with that
   quad, under a warning saying the layer is being coloured on purpose, so
   this checks what actually reaches the drawable.

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

static CALayer *plainTree(CGColorRef fill, BOOL rasterised)
{
  CALayer *root = [CALayer layer];
  CALayer *layer = [CALayer layer];

  [root setBounds: CGRectMake(0, 0, VIEW_W, VIEW_H)];
  [root setPosition: CGPointMake(VIEW_W / 2.0, VIEW_H / 2.0)];
  [layer setBounds: CGRectMake(0, 0, 20, 14)];
  [layer setPosition: CGPointMake(VIEW_W / 2.0, VIEW_H / 2.0)];
  [layer setBackgroundColor: fill];
  [layer setShouldRasterize: rasterised];
  [root addSublayer: layer];
  return root;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what drawing a layer offscreen does to its colour")

  const char *why = "";
  NSOpenGLContext *context = usableContext(&why);
  CARenderer *renderer;
  static unsigned char direct[MAX_PIXELS];
  static unsigned char offscreen[MAX_PIXELS];
  long middle;

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
  CGColorRef white = CGColorCreateGenericRGB(1, 1, 1, 1);
  CALayer *bare = plainTree(white, NO);
  CALayer *rasterised = plainTree(white, YES);
  [CATransaction commit];

  renderFrame(renderer, bare);
  readDrawable(direct);
  renderFrame(renderer, rasterised);
  readDrawable(offscreen);

  middle = ((drawableH / 2) * drawableW + drawableW / 2) * 4;

  PASS(direct[middle] > 200 && direct[middle + 1] > 200
       && direct[middle + 2] > 200,
       "a white layer drawn straight to the drawable is white");
  PASS(memcmp(direct + middle, offscreen + middle, 4) == 0,
       "and is the same colour when it is drawn offscreen first");

  CGColorRelease(white);

  END_SET("what drawing a layer offscreen does to its colour")

  [pool release];
  return 0;
}
