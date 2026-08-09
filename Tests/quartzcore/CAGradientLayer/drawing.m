/* What a gradient layer draws when it is rendered into a context.  Every
   expected value here was measured against Apple QuartzCore.

   Opal and CoreGraphics interpolate and lay out a pixel differently, so what
   is asserted is which pixels are covered and the order the colours run in,
   never an exact colour except where a colour is flat. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CAGradientLayer.h>
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

static CGColorRef opaque(CGFloat r, CGFloat g, CGFloat b)
{
  return CGColorCreateGenericRGB(r, g, b, 1.0);
}

/* Which byte of a pixel carries which colour.  The two rasterisers lay a
   pixel out differently, so the test finds the bytes by drawing a colour it
   knows rather than naming a layout. */
static int chR = 0, chG = 1, chB = 2;

static int channelOf(CGFloat r, CGFloat g, CGFloat b)
{
  CGContextRef context = newContext();
  CALayer *l = [CALayer layer];
  CGColorRef colour = opaque(r, g, b);
  unsigned char *p;
  int i, found = 0;

  [l setBounds: CGRectMake(0, 0, 20, 20)];
  [l setBackgroundColor: colour];
  [l renderInContext: context];
  p = (unsigned char *)CGBitmapContextGetData(context)
      + ((SIDE - 1 - 10) * SIDE + 10) * 4;

  /* Half strength, so the channel is the one byte near 128 rather than one
     of the several at 255. */
  for (i = 0; i < 4; i++)
    if (p[i] > 100 && p[i] < 160)
      found = i;

  CGColorRelease(colour);
  CGContextRelease(context);
  return found;
}

static void findTheChannels(void)
{
  chR = channelOf(0.5, 0, 0);
  chG = channelOf(0, 0.5, 0);
  chB = channelOf(0, 0, 0.5);
  PASS(chR != chG && chG != chB && chR != chB,
       "red, green and blue are each in a byte of their own");
}

/* The colour at a point, as three channels. */
static void channels(CGContextRef context, int x, int y,
                     int *r, int *g, int *b)
{
  unsigned char *data = CGBitmapContextGetData(context);
  unsigned char *p = data + ((SIDE - 1 - y) * SIDE + x) * 4;

  *r = p[chR];
  *g = p[chG];
  *b = p[chB];
}

static CGImageRef greenImage(int w, int h)
{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef c = CGBitmapContextCreate(NULL, w, h, 8, w * 4, space,
#if GNUSTEP
                                         kCGImageAlphaPremultipliedFirst);
#else
                                         kCGImageAlphaPremultipliedLast);
#endif
  CGColorRef green = opaque(0, 1, 0);
  CGImageRef image;

  CGColorSpaceRelease(space);
  memset(CGBitmapContextGetData(c), 0, w * h * 4);
  CGContextSetFillColorWithColor(c, green);
  CGContextFillRect(c, CGRectMake(0, 0, w, h));
  image = CGBitmapContextCreateImage(c);
  CGColorRelease(green);
  CGContextRelease(c);
  return image;
}

static CAGradientLayer *gradient(NSArray *colors)
{
  CAGradientLayer *g = [CAGradientLayer layer];

  [g setBounds: CGRectMake(0, 0, 80, 60)];
  [g setColors: colors];
  return g;
}

static void acrossTheBounds(void)
{
  CGColorRef red = opaque(1, 0, 0);
  CGColorRef blue = opaque(0, 0, 1);
  NSArray *two = [NSArray arrayWithObjects: (id)red, (id)blue, nil];
  CGContextRef context = newContext();
  CAGradientLayer *g = gradient(two);
  int r0, g0, b0, r1, g1, b1;

  [g renderInContext: context];
  PASS(paintedExactly(context, 0, 0, 80, 60),
       "a gradient covers the whole of the layer's bounds");
  PASS(paintedCount(context) == 4800, "and nothing outside them");

  channels(context, 40, 2, &r0, &g0, &b0);
  channels(context, 40, 57, &r1, &g1, &b1);
  PASS(r0 > b0, "the colour it starts with is at the bottom");
  PASS(b1 > r1, "and the one it ends with is at the top");
  CGContextRelease(context);

  /* The colours run one way the whole distance. */
  context = newContext();
  CAGradientLayer *up = gradient(two);
  int last_r = 256, last_b = -1, y;
  BOOL monotonic = YES;

  [up renderInContext: context];
  for (y = 2; y <= 57; y += 5)
    {
      int r, gg, b;

      channels(context, 40, y, &r, &gg, &b);
      if (r > last_r || b < last_b)
        monotonic = NO;
      last_r = r;
      last_b = b;
    }
  PASS(monotonic, "red gives way to blue the whole way up, and never back");
  CGContextRelease(context);

  CGColorRelease(red);
  CGColorRelease(blue);
}

static void whichWayItRuns(void)
{
  CGColorRef red = opaque(1, 0, 0);
  CGColorRef blue = opaque(0, 0, 1);
  NSArray *two = [NSArray arrayWithObjects: (id)red, (id)blue, nil];
  CGContextRef context = newContext();
  CAGradientLayer *sideways = gradient(two);
  int lr, lg, lb, rr, rg, rb;

  [sideways setStartPoint: CGPointMake(0, 0.5)];
  [sideways setEndPoint: CGPointMake(1, 0.5)];
  [sideways renderInContext: context];
  PASS(paintedCount(context) == 4800, "a sideways gradient covers as much");
  channels(context, 2, 30, &lr, &lg, &lb);
  channels(context, 77, 30, &rr, &rg, &rb);
  PASS(lr > lb && rb > rr, "and runs from the left to the right");
  CGContextRelease(context);

  context = newContext();
  CAGradientLayer *down = gradient(two);
  [down setStartPoint: CGPointMake(0.5, 1)];
  [down setEndPoint: CGPointMake(0.5, 0)];
  [down renderInContext: context];
  channels(context, 40, 2, &lr, &lg, &lb);
  PASS(lb > lr, "and turning the points around turns the gradient around");
  CGContextRelease(context);

  /* Outside the two points the end colours carry on to the edge. */
  context = newContext();
  CAGradientLayer *middle = gradient(two);
  [middle setStartPoint: CGPointMake(0.5, 0.25)];
  [middle setEndPoint: CGPointMake(0.5, 0.75)];
  [middle renderInContext: context];
  PASS(paintedCount(context) == 4800,
       "a gradient over part of the bounds still covers all of them");
  channels(context, 40, 2, &lr, &lg, &lb);
  PASS(lr > 240 && lb < 20, "the colour before it starts is flat");
  CGContextRelease(context);

  CGColorRelease(red);
  CGColorRelease(blue);
}

static void nothingToDraw(void)
{
  CGColorRef red = opaque(1, 0, 0);
  CGContextRef context = newContext();
  CAGradientLayer *none = gradient(nil);

  [none renderInContext: context];
  PASS(paintedCount(context) == 0, "with no colours a gradient draws nothing");
  CGContextRelease(context);

  context = newContext();
  CAGradientLayer *one = gradient([NSArray arrayWithObject: (id)red]);
  [one renderInContext: context];
  PASS(paintedCount(context) == 0, "and one colour is not enough either");
  CGContextRelease(context);

  context = newContext();
  CAGradientLayer *empty = gradient([NSArray array]);
  [empty renderInContext: context];
  PASS(paintedCount(context) == 0, "nor is an empty array");
  CGContextRelease(context);

  CGColorRelease(red);
}

static void whereTheColoursSit(void)
{
  CGColorRef red = opaque(1, 0, 0);
  CGColorRef green = opaque(0, 1, 0);
  CGColorRef blue = opaque(0, 0, 1);
  NSArray *three = [NSArray arrayWithObjects: (id)red, (id)green, (id)blue,
                            nil];
  CGContextRef context = newContext();
  CAGradientLayer *placed = gradient(three);
  int r, g, b;

  [placed setLocations: [NSArray arrayWithObjects:
                           [NSNumber numberWithFloat: 0.0],
                           [NSNumber numberWithFloat: 0.25],
                           [NSNumber numberWithFloat: 1.0], nil]];
  [placed renderInContext: context];
  channels(context, 40, 15, &r, &g, &b);
  PASS(g > r && g > b,
       "a colour is where its location puts it, a quarter of the way up");
  CGContextRelease(context);

  context = newContext();
  CAGradientLayer *mismatched = gradient(three);
  [mismatched setLocations: [NSArray arrayWithObject:
                               [NSNumber numberWithFloat: 0.5]]];
  [mismatched renderInContext: context];
  PASS(paintedCount(context) == 0,
       "with fewer locations than colours nothing is drawn");
  CGContextRelease(context);

  /* Two colours at the same location step from one to the other. */
  context = newContext();
  CAGradientLayer *stepped = gradient([NSArray arrayWithObjects: (id)red,
                                               (id)blue, nil]);
  [stepped setLocations: [NSArray arrayWithObjects:
                            [NSNumber numberWithFloat: 0.5],
                            [NSNumber numberWithFloat: 0.5], nil]];
  [stepped renderInContext: context];
  channels(context, 40, 25, &r, &g, &b);
  PASS(r > 240 && b < 20, "below a hard stop the first colour is flat");
  channels(context, 40, 35, &r, &g, &b);
  PASS(b > 240 && r < 20, "and above it the second is");
  CGContextRelease(context);

  CGColorRelease(red);
  CGColorRelease(green);
  CGColorRelease(blue);
}

static void underTheContents(void)
{
  CGColorRef red = opaque(1, 0, 0);
  CGColorRef blue = opaque(0, 0, 1);
  NSArray *two = [NSArray arrayWithObjects: (id)red, (id)blue, nil];
  CGImageRef image = greenImage(20, 10);
  CGContextRef context = newContext();
  CAGradientLayer *g = gradient(two);
  int r, gg, b;

  [g setContents: (id)image];
  [g setContentsGravity: kCAGravityCenter];
  [g renderInContext: context];
  PASS(paintedCount(context) == 4800, "a gradient under contents covers all");
  channels(context, 40, 30, &r, &gg, &b);
  PASS(gg > r && gg > b, "the contents are drawn over the gradient");
  channels(context, 5, 30, &r, &gg, &b);
  PASS(r > gg && b > gg, "and the gradient shows where they are not");

  CGImageRelease(image);
  CGContextRelease(context);
  CGColorRelease(red);
  CGColorRelease(blue);
}

static void roundedAtTheCorners(void)
{
  CGColorRef red = opaque(1, 0, 0);
  CGColorRef blue = opaque(0, 0, 1);
  NSArray *two = [NSArray arrayWithObjects: (id)red, (id)blue, nil];
  CGContextRef context = newContext();
  CAGradientLayer *square = gradient(two);
  int plain, rounded;

  [square renderInContext: context];
  plain = paintedCount(context);
  PASS(painted(context, 0, 0), "a square gradient reaches into the corner");
  CGContextRelease(context);

  context = newContext();
  CAGradientLayer *round = gradient(two);
  [round setCornerRadius: 20];
  [round renderInContext: context];
  rounded = paintedCount(context);
  PASS(!painted(context, 0, 0) && !painted(context, 1, 1),
       "a corner radius takes the corner off the gradient");
  PASS(rounded < plain && rounded > plain * 9 / 10,
       "which costs it the corners and nothing else");
  PASS(painted(context, 40, 30) && painted(context, 0, 30),
       "the middle and the straight edges are still covered");
  CGContextRelease(context);

  CGColorRelease(red);
  CGColorRelease(blue);
}

/* A radial gradient is an ellipse centred on startPoint, with radii
   |endPoint.x - startPoint.x| by the width and |endPoint.y - startPoint.y| by
   the height.  Apple draws nothing when the two points share either axis. */
static void radially(void)
{
  CGColorRef red = opaque(1, 0, 0);
  CGColorRef blue = opaque(0, 0, 1);
  NSArray *two = [NSArray arrayWithObjects: (id)red, (id)blue, nil];
  CGContextRef context = newContext();
  CGContextRef flat = newContext();
  CAGradientLayer *g = gradient(two);
  CAGradientLayer *sameAxis = gradient(two);
  int cr, cg, cb, er, eg, eb;

  [g setType: kCAGradientLayerRadial];
  [g setStartPoint: CGPointMake(0.5, 0.5)];
  [g setEndPoint: CGPointMake(1.0, 1.0)];
  [g renderInContext: context];

  PASS(paintedExactly(context, 0, 0, 80, 60),
       "a radial gradient covers the whole of the layer's bounds");
  channels(context, 40, 30, &cr, &cg, &cb);
  channels(context, 2, 2, &er, &eg, &eb);
  PASS(cr > cb && er < eb,
       "with the first colour at its centre and the last at a corner");

  [sameAxis setType: kCAGradientLayerRadial];
  [sameAxis setStartPoint: CGPointMake(0.5, 0.0)];
  [sameAxis setEndPoint: CGPointMake(0.5, 1.0)];
  [sameAxis renderInContext: flat];
  PASS(paintedCount(flat) == 0,
       "and two points on the same axis draw nothing");

  CGColorRelease(red);
  CGColorRelease(blue);
  CGContextRelease(context);
  CGContextRelease(flat);
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what a gradient layer draws")

  findTheChannels();
  acrossTheBounds();
  whichWayItRuns();
  nothingToDraw();
  whereTheColoursSit();
  underTheContents();
  roundedAtTheCorners();
  radially();

  END_SET("what a gradient layer draws")

  [pool release];
  return 0;
}
