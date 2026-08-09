/* A layer whose content is its own, rather than something a delegate draws,
   puts it there by overriding -drawContentInContext:.  That method belongs to
   this framework and Apple does not declare it, so this file does not run
   there.

   As in render.m, a pixel counts as painted when any of its four bytes is not
   zero, which for an opaque colour on a cleared context is exact. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>
#include <string.h>

#define SIDE 100

@interface CALayer (FrameworkPrivate)
- (void) drawContentInContext: (CGContextRef)context;
- (void) drawBackgroundInContext: (CGContextRef)context;
@end

static CGContextRef newContext(void)
{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef context;

  context = CGBitmapContextCreate(NULL, SIDE, SIDE, 8, SIDE * 4, space,
                                  kCGImageAlphaPremultipliedFirst);
  CGColorSpaceRelease(space);
  if (context)
    {
      memset(CGBitmapContextGetData(context), 0, SIDE * SIDE * 4);
    }
  return context;
}

/* Whether the pixel at (x, y) had anything drawn on it.  y counts up from
   the bottom, the way the layer geometry does. */
static BOOL painted(CGContextRef context, int x, int y)
{
  unsigned char *data = CGBitmapContextGetData(context);
  unsigned char *pixel;

  if (!data || x < 0 || y < 0 || x >= SIDE || y >= SIDE)
    return NO;
  pixel = data + ((SIDE - 1 - y) * SIDE + x) * 4;
  return pixel[0] || pixel[1] || pixel[2] || pixel[3];
}

static int paintedCount(CGContextRef context)
{
  int x, y, n = 0;

  for (y = 0; y < SIDE; y++)
    for (x = 0; x < SIDE; x++)
      if (painted(context, x, y))
        n++;
  return n;
}

/* Whether everything painted lies in x [x0, x1) by y [y0, y1) and fills it. */
static BOOL paintedExactly(CGContextRef context, int x0, int y0,
                           int x1, int y1)
{
  int x, y;

  for (y = 0; y < SIDE; y++)
    for (x = 0; x < SIDE; x++)
      {
        BOOL inside = (x >= x0 && x < x1 && y >= y0 && y < y1);

        if (painted(context, x, y) != inside)
          return NO;
      }
  return YES;
}

/* Whether the two contexts hold the same pixel at that point. */
static BOOL samePixel(CGContextRef a, CGContextRef b, int x, int y)
{
  long o = ((SIDE - 1 - y) * SIDE + x) * 4;

  return memcmp((unsigned char *)CGBitmapContextGetData(a) + o,
                (unsigned char *)CGBitmapContextGetData(b) + o, 4) == 0;
}

/* An opaque image, for a layer's contents. */
static CGImageRef blueImage(int w, int h)
{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef c = CGBitmapContextCreate(NULL, w, h, 8, w * 4, space,
                                         kCGImageAlphaPremultipliedFirst);
  CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);
  CGImageRef image;

  CGColorSpaceRelease(space);
  memset(CGBitmapContextGetData(c), 0, w * h * 4);
  CGContextSetFillColorWithColor(c, blue);
  CGContextFillRect(c, CGRectMake(0, 0, w, h));
  image = CGBitmapContextCreateImage(c);
  CGColorRelease(blue);
  CGContextRelease(c);
  return image;
}

@interface Shaped : CALayer
@end

@implementation Shaped
- (void) drawContentInContext: (CGContextRef)context
{
  CGColorRef red = CGColorCreateGenericRGB(1, 0, 0, 1);

  CGContextSetFillColorWithColor(context, red);
  CGContextFillRect(context, CGRectMake(0, 0, 10, 10));
  CGColorRelease(red);
}
@end

@interface Backed : CALayer
@end

@implementation Backed
- (void) drawBackgroundInContext: (CGContextRef)context
{
  CGColorRef red = CGColorCreateGenericRGB(1, 0, 0, 1);

  CGContextSetFillColorWithColor(context, red);
  CGContextFillRect(context, CGRectMake(0, 0, 40, 40));
  CGColorRelease(red);
}
@end

@interface Drawer : NSObject
@end

@implementation Drawer
- (void) drawLayer: (CALayer *)layer inContext: (CGContextRef)context
{
  CGColorRef green = CGColorCreateGenericRGB(0, 1, 0, 1);

  CGContextSetFillColorWithColor(context, green);
  CGContextFillRect(context, CGRectMake(20, 20, 10, 10));
  CGColorRelease(green);
}
@end

static void aSubclassThatDraws(void)
{
  CGContextRef context = newContext();
  Shaped *s = [Shaped layer];

  [s setBounds: CGRectMake(0, 0, 40, 40)];
  [s renderInContext: context];
  PASS(paintedExactly(context, 0, 0, 10, 10),
       "a subclass draws its own content when the layer is rendered");
  CGContextRelease(context);
}

static void aPlainLayerDrawsNothing(void)
{
  CGContextRef context = newContext();
  CALayer *l = [CALayer layer];

  [l setBounds: CGRectMake(0, 0, 40, 40)];
  [l renderInContext: context];
  PASS(paintedCount(context) == 0,
       "a layer that is not a subclass has no content of its own");
  CGContextRelease(context);
}

/* What the layer draws for itself and what its delegate draws both reach the
   backing store, so a subclass with a delegate shows the two together. */
static void bothReachTheBackingStore(void)
{
  CGContextRef context = newContext();
  Shaped *s = [Shaped layer];
  Drawer *drawer = [[Drawer new] autorelease];

  [s setBounds: CGRectMake(0, 0, 40, 40)];
  [s setDelegate: drawer];
  [s display];
  [s renderInContext: context];
  PASS(painted(context, 5, 5) && painted(context, 25, 25),
       "once it has been displayed, the layer's own drawing and its "
       "delegate's are both there");
  CGContextRelease(context);
}

/* A layer's own drawing has two places it can go: under the contents, where
   a gradient goes, and over them, where a shape goes. */
static void whichSideOfTheContents(void)
{
  CGImageRef image = blueImage(40, 40);
  CGContextRef context = newContext();
  Backed *under = [Backed layer];

  [under setBounds: CGRectMake(0, 0, 40, 40)];
  [under renderInContext: context];
  PASS(paintedExactly(context, 0, 0, 40, 40),
       "a layer drawing its background covers its bounds");
  CGContextRelease(context);

  CGContextRef backed = newContext();
  Backed *b = [Backed layer];
  [b setBounds: CGRectMake(0, 0, 40, 40)];
  [b setContents: (id)image];
  [b renderInContext: backed];

  CGContextRef plain = newContext();
  CALayer *p = [CALayer layer];
  [p setBounds: CGRectMake(0, 0, 40, 40)];
  [p setContents: (id)image];
  [p renderInContext: plain];

  PASS(samePixel(backed, plain, 20, 20),
       "what a layer draws for its background is hidden by its contents");

  CGContextRef shaped = newContext();
  Shaped *s = [Shaped layer];
  [s setBounds: CGRectMake(0, 0, 40, 40)];
  [s setContents: (id)image];
  [s renderInContext: shaped];
  PASS(!samePixel(shaped, plain, 5, 5),
       "while what it draws as content is over them");

  CGImageRelease(image);
  CGContextRelease(backed);
  CGContextRelease(plain);
  CGContextRelease(shaped);
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what a layer draws for itself")

  aSubclassThatDraws();
  aPlainLayerDrawsNothing();
  bothReachTheBackingStore();
  whichSideOfTheContents();

  END_SET("what a layer draws for itself")

  [pool release];
  return 0;
}
