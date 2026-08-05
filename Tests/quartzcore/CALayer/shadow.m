/* -renderInContext: draws a layer's shadow.  Every expected value here was
   measured against Apple QuartzCore: the shadow is cast by the layer and
   everything under it taken together, a layer's shadowRadius of r spreads it
   2r on each side, a layer that draws nothing casts none, and shadowPath is
   not read.

   As in render.m the assertions are about which pixels are painted rather
   than what is in each byte of them, Opal and Apple laying a pixel out
   differently.

   A shadow reaches the context through a transparency layer, and a build
   whose CoreGraphics does not composite one with the context's shadow draws
   nothing here for reasons that have nothing to do with CALayer, so that is
   checked for and the set skipped. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>
#include <string.h>

#define SIDE 200

/* The layer is 40x40 and the context is translated by this much before it is
   drawn, so it covers 80..119 in both directions. */
#define PLACE 80
#define OFFSET 20
#define RADIUS 5

static CGContextRef newContext(void)
{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef context;

  context = CGBitmapContextCreate(NULL, SIDE, SIDE, 8, SIDE * 4, space,
#if GNUSTEP
                                  kCGImageAlphaPremultipliedFirst);
#else
                                  kCGImageAlphaPremultipliedLast);
#endif
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

/* Whether this build's CoreGraphics composites a transparency layer with the
   shadow the context carries.  Without that a layer's shadow cannot reach
   the context at all. */
static BOOL castsTransparencyLayerShadows(void)
{
  /* Held for good rather than released: a build that does not keep the
     shadow colour across a saved graphics state releases this one when the
     transparency layer turns the shadow off, and releasing it here as well
     ends the process before it can be found out that the build is that
     one. */
  static CGColorRef blue = NULL;
  CGContextRef context = newContext();
  BOOL casts;

  if (context == NULL)
    return NO;
  if (blue == NULL)
    blue = CGColorCreateGenericRGB(0, 0, 1, 1);

  CGContextSetShadowWithColor(context, CGSizeMake(40, 40), 0, blue);
  CGContextBeginTransparencyLayer(context, NULL);
  CGContextSetRGBFillColor(context, 1, 0, 0, 1);
  CGContextFillRect(context, CGRectMake(20, 20, 20, 20));
  CGContextEndTransparencyLayer(context);

  /* Where the shadow lands, well clear of the rect itself. */
  casts = painted(context, 70, 70);

  CGContextRelease(context);
  return casts;
}

static CALayer *shadowedLayer(CGColorRef fill, CGColorRef shade)
{
  CALayer *layer = [CALayer layer];

  [layer setBounds: CGRectMake(0, 0, 40, 40)];
  [layer setBackgroundColor: fill];
  [layer setShadowColor: shade];
  [layer setShadowOpacity: 1.0];
  [layer setShadowOffset: CGSizeMake(OFFSET, OFFSET)];
  [layer setShadowRadius: RADIUS];
  return layer;
}

static CGContextRef drawn(CALayer *layer)
{
  CGContextRef context = newContext();

  if (context == NULL)
    return NULL;
  CGContextTranslateCTM(context, PLACE, PLACE);
  [layer renderInContext: context];
  return context;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the shadow -renderInContext: draws")

  CGColorRef red = CGColorCreateGenericRGB(1, 0, 0, 1);
  CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);
  CGColorRef green = CGColorCreateGenericRGB(0, 1, 0, 1);
  CGContextRef context;
  CALayer *layer;
  int plain;

  if (newContext() == NULL)
    {
      SKIP("there is no bitmap context to draw into")
    }

  if (castsTransparencyLayerShadows() == NO)
    {
      SKIP("this build composites a transparency layer without the shadow")
    }

  /* The far edge of the shadow is the layer's edge moved by the offset and
     grown by twice the radius: 119 + 20 + 10.  The edge is read halfway up
     the shadow rather than at its corner, a blur rounding its corners
     off. */
  context = drawn(shadowedLayer(red, blue));
  plain = paintedCount(context);
  PASS(painted(context, 140, 140),
       "a layer with a shadow paints outside itself");
  PASS(painted(context, 149, 120),
       "as far as the offset and twice the radius reach");
  PASS(!painted(context, 152, 120), "and no further");
  CGContextRelease(context);

  /* A layer that draws nothing has nothing to cast a shadow from. */
  layer = shadowedLayer(red, blue);
  [layer setBackgroundColor: NULL];
  context = drawn(layer);
  PASS(paintedCount(context) == 0,
       "a layer that draws nothing casts no shadow");
  CGContextRelease(context);

  /* One shadow for the layer and its sublayers together, so a sublayer
     reaching past the layer reaches past its shadow as well. */
  layer = shadowedLayer(red, blue);
  {
    CALayer *out = [CALayer layer];

    [out setBounds: CGRectMake(0, 0, 20, 20)];
    [out setPosition: CGPointMake(50, 20)];
    [out setBackgroundColor: green];
    [layer addSublayer: out];
  }
  context = drawn(layer);
  PASS(painted(context, 165, 120),
       "a sublayer reaching past the layer casts a shadow of its own");
  CGContextRelease(context);

  /* shadowPath is not read here. */
  layer = shadowedLayer(red, blue);
  {
    CGMutablePathRef path = CGPathCreateMutable();

    CGPathAddEllipseInRect(path, NULL, CGRectMake(10, 10, 20, 20));
    [layer setShadowPath: path];
    CGPathRelease(path);
  }
  context = drawn(layer);
  PASS(paintedCount(context) == plain,
       "a shadowPath makes no difference to what is drawn");
  CGContextRelease(context);

  CGColorRelease(red);
  CGColorRelease(blue);
  CGColorRelease(green);

  END_SET("the shadow -renderInContext: draws")

  [pool release];
  return 0;
}
