/* What a shape layer draws when it is rendered into a context.  Every
   expected value here was measured against Apple QuartzCore.

   As in Tests/quartzcore/CALayer/render.m, the assertions are about which
   pixels are painted rather than what is in each byte of them, Opal and
   CoreGraphics laying a pixel out differently.  A pixel counts as painted
   when any of its four bytes is not zero. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CAShapeLayer.h>
#import <CoreGraphics/CoreGraphics.h>
#include <string.h>

#define SIDE 100

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

static CGPathRef rectPath(CGRect r)
{
  CGMutablePathRef p = CGPathCreateMutable();

  CGPathAddRect(p, NULL, r);
  return p;
}

static CAShapeLayer *shape(CGPathRef path)
{
  CAShapeLayer *s = [CAShapeLayer layer];

  [s setBounds: CGRectMake(0, 0, 80, 60)];
  [s setPath: path];
  return s;
}

static void fills(void)
{
  CGPathRef path = rectPath(CGRectMake(10, 10, 40, 30));
  CGContextRef context = newContext();
  CAShapeLayer *s = shape(path);

  [s renderInContext: context];
  PASS(paintedExactly(context, 10, 10, 50, 40),
       "a shape layer fills its path with the colour it starts with");
  PASS(paintedCount(context) == 1200, "and fills nothing else");
  CGContextRelease(context);

  context = newContext();
  CAShapeLayer *unfilled = shape(path);
  [unfilled setFillColor: NULL];
  [unfilled renderInContext: context];
  PASS(paintedCount(context) == 0, "with no fill colour it fills nothing");
  CGContextRelease(context);

  context = newContext();
  CAShapeLayer *pathless = [CAShapeLayer layer];
  [pathless setBounds: CGRectMake(0, 0, 80, 60)];
  [pathless renderInContext: context];
  PASS(paintedCount(context) == 0, "and with no path it draws nothing");
  CGContextRelease(context);

  /* The path is in the layer's own coordinates and is not cut to them. */
  CGPathRef over = rectPath(CGRectMake(60, 40, 30, 30));
  context = newContext();
  CAShapeLayer *hanging = shape(over);
  [hanging renderInContext: context];
  PASS(paintedCount(context) == 900,
       "a path running past the bounds is drawn whole");
  CGContextRelease(context);

  context = newContext();
  CAShapeLayer *masked = shape(over);
  [masked setMasksToBounds: YES];
  [masked renderInContext: context];
  PASS(paintedCount(context) == 400, "unless the layer masks to its bounds");
  CGContextRelease(context);

  CGPathRelease(over);
  CGPathRelease(path);
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what a shape layer draws")

  fills();

  END_SET("what a shape layer draws")

  [pool release];
  return 0;
}
