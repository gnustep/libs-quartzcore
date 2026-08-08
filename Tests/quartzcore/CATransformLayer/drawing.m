/* What a transform layer draws when it is rendered into a context.  The
   expected values were measured against Apple QuartzCore with a 100 by 100
   layer at the origin of a 200 by 100 context.

   Apple's -renderInContext: draws a CATransformLayer as it draws a CALayer:
   the background, the border and masksToBounds all apply.  The documented
   difference, that a transform layer has no content of its own, is a
   compositor behaviour, and it is asserted of CARenderer in
   Tests/quartzcore/CARenderer/renderer.m. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CATransformLayer.h>
#import <CoreGraphics/CoreGraphics.h>
#include <string.h>

#define W 200
#define H 100
#define LAYER 100

static CGContextRef newContext(void)
{
  CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  CGContextRef context;

  context = CGBitmapContextCreate(NULL, W, H, 8, W * 4, space,
#if GNUSTEP
                                  kCGImageAlphaPremultipliedFirst);
#else
                                  kCGImageAlphaPremultipliedLast);
#endif
  CGColorSpaceRelease(space);
  if (context)
    {
      memset(CGBitmapContextGetData(context), 0, W * H * 4);
    }
  return context;
}

/* Whether the pixel at (x, y) had anything drawn on it.  y counts up from
   the bottom, the way the layer geometry does. */
static BOOL painted(CGContextRef context, int x, int y)
{
  unsigned char *data = CGBitmapContextGetData(context);
  unsigned char *pixel;

  if (!data || x < 0 || y < 0 || x >= W || y >= H)
    return NO;
  pixel = data + ((H - 1 - y) * W + x) * 4;
  return pixel[0] || pixel[1] || pixel[2] || pixel[3];
}

static int paintedCount(CGContextRef context)
{
  int x, y, n = 0;

  for (y = 0; y < H; y++)
    for (x = 0; x < W; x++)
      if (painted(context, x, y))
        n++;
  return n;
}

static BOOL paintedBox(CGContextRef context, int *x0, int *y0,
                       int *x1, int *y1)
{
  int x, y;

  *x0 = W; *y0 = H; *x1 = -1; *y1 = -1;
  for (y = 0; y < H; y++)
    for (x = 0; x < W; x++)
      if (painted(context, x, y))
        {
          if (x < *x0) *x0 = x;
          if (y < *y0) *y0 = y;
          if (x > *x1) *x1 = x;
          if (y > *y1) *y1 = y;
        }
  return *x1 >= 0;
}

static CGColorRef opaque(CGFloat r, CGFloat g, CGFloat b)
{
  return CGColorCreateGenericRGB(r, g, b, 1.0);
}

static CALayer *redChild(void)
{
  CALayer *l = [CALayer layer];
  CGColorRef red = opaque(1, 0, 0);

  [l setBounds: CGRectMake(0, 0, 20, 20)];
  [l setPosition: CGPointMake(10, 10)];
  [l setBackgroundColor: red];
  CGColorRelease(red);
  return l;
}

static void itDrawsItsSublayers(void)
{
  CGContextRef context = newContext();
  CGContextRef plain = newContext();
  CATransformLayer *t = [CATransformLayer layer];
  CALayer *l = [CALayer layer];
  int x0, y0, x1, y1, px0, py0, px1, py1;

  [t setBounds: CGRectMake(0, 0, LAYER, LAYER)];
  [t addSublayer: redChild()];
  [t renderInContext: context];

  [l setBounds: CGRectMake(0, 0, LAYER, LAYER)];
  [l addSublayer: redChild()];
  [l renderInContext: plain];

  PASS(paintedBox(context, &x0, &y0, &x1, &y1),
       "a transform layer draws its sublayers");
  paintedBox(plain, &px0, &py0, &px1, &py1);
  PASS(x0 == px0 && y0 == py0 && x1 == px1 && y1 == py1,
       "in the box a plain layer draws the same sublayer in");
  PASS(paintedCount(context) == paintedCount(plain),
       "covering the same number of points");

  CGContextRelease(context);
  CGContextRelease(plain);
}

/* -renderInContext: draws the background and the border of a transform
   layer. */
static void itDrawsWhatAPlainLayerDraws(void)
{
  CGContextRef background = newContext();
  CGContextRef border = newContext();
  CGContextRef plainBorder = newContext();
  CATransformLayer *t = [CATransformLayer layer];
  CATransformLayer *edged = [CATransformLayer layer];
  CALayer *plain = [CALayer layer];
  CGColorRef green = opaque(0, 1, 0);
  CGColorRef white = opaque(1, 1, 1);

  [t setBounds: CGRectMake(0, 0, LAYER, LAYER)];
  [t setBackgroundColor: green];
  [t renderInContext: background];
  PASS(paintedCount(background) == LAYER * LAYER,
       "a transform layer paints its background over its whole bounds");

  [edged setBounds: CGRectMake(0, 0, LAYER, LAYER)];
  [edged setBorderWidth: 5];
  [edged setBorderColor: white];
  [edged renderInContext: border];

  [plain setBounds: CGRectMake(0, 0, LAYER, LAYER)];
  [plain setBorderWidth: 5];
  [plain setBorderColor: white];
  [plain renderInContext: plainBorder];
  PASS(paintedCount(border) == paintedCount(plainBorder)
       && paintedCount(border) > 0,
       "and its border, as a plain layer does");

  CGColorRelease(green);
  CGColorRelease(white);
  CGContextRelease(background);
  CGContextRelease(border);
  CGContextRelease(plainBorder);
}

static void itClipsLikeAPlainLayer(void)
{
  CGContextRef context = newContext();
  CGContextRef plain = newContext();
  CATransformLayer *t = [CATransformLayer layer];
  CALayer *l = [CALayer layer];
  CALayer *big = redChild();
  CALayer *plainBig = redChild();

  [big setBounds: CGRectMake(0, 0, 400, 400)];
  [t setBounds: CGRectMake(0, 0, 50, 50)];
  [t setMasksToBounds: YES];
  [t addSublayer: big];
  [t renderInContext: context];

  [plainBig setBounds: CGRectMake(0, 0, 400, 400)];
  [l setBounds: CGRectMake(0, 0, 50, 50)];
  [l setMasksToBounds: YES];
  [l addSublayer: plainBig];
  [l renderInContext: plain];

  PASS(paintedCount(context) == 50 * 50,
       "masksToBounds cuts the sublayers of a transform layer to its bounds");
  PASS(paintedCount(context) == paintedCount(plain),
       "as it does on a plain layer");

  CGContextRelease(context);
  CGContextRelease(plain);
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what a transform layer draws")

  itDrawsItsSublayers();
  itDrawsWhatAPlainLayerDraws();
  itClipsLikeAPlainLayer();

  END_SET("what a transform layer draws")

  [pool release];
  return 0;
}
