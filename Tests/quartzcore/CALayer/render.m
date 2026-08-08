/* -renderInContext: draws a layer and everything under it into a Core
   Graphics context.  Every expected value here was measured against Apple
   QuartzCore.

   The assertions are about which pixels are painted, not about what is in
   each byte of them: Opal and Apple lay a pixel out differently, Opal taking
   only premultiplied-first, so a test that read a particular byte would
   answer differently on the two for reasons that have nothing to do with
   this method.  A pixel counts as painted when any of its four bytes is not
   zero, which for an opaque colour on a cleared context is exact. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>
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

static BOOL fullyPainted(CGContextRef context)
{
  unsigned char *data = CGBitmapContextGetData(context);
  int i;

  for (i = 0; i < SIDE * SIDE; i++)
    {
      unsigned char *p = data + i * 4;

      if (p[0] || p[1] || p[2] || p[3])
        {
          if (p[0] != 255 && p[1] != 255 && p[2] != 255 && p[3] != 255)
            return NO;
        }
    }
  return YES;
}

static CGColorRef opaque(CGFloat r, CGFloat g, CGFloat b)
{
  return CGColorCreateGenericRGB(r, g, b, 1.0);
}

static void whereTheLayerLands(void)
{
  CGContextRef context = newContext();
  CALayer *l = [CALayer layer];
  CGColorRef red = opaque(1, 0, 0);

  PASS(context != NULL, "a bitmap context can be made to draw into");

  [l setFrame: CGRectMake(10, 20, 30, 40)];
  [l setBackgroundColor: red];
  [l renderInContext: context];
  PASS(paintedExactly(context, 0, 0, 30, 40),
       "the layer asked to render is drawn at the origin of the context, "
       "not where its own frame puts it");
  CGContextRelease(context);

  /* Its bounds origin, however, is where its own drawing goes. */
  context = newContext();
  CALayer *b = [CALayer layer];
  [b setBounds: CGRectMake(10, 10, 20, 20)];
  [b setPosition: CGPointMake(50, 50)];
  [b setBackgroundColor: red];
  [b renderInContext: context];
  PASS(paintedExactly(context, 10, 10, 30, 30),
       "a bounds origin moves that drawing, a position does not");
  CGContextRelease(context);

  /* Nor does a transform on the layer that was asked. */
  context = newContext();
  CALayer *t = [CALayer layer];
  [t setFrame: CGRectMake(10, 10, 20, 20)];
  [t setBackgroundColor: red];
  [t setTransform: CATransform3DMakeTranslation(30, 0, 0)];
  [t renderInContext: context];
  PASS(paintedExactly(context, 0, 0, 20, 20),
       "and neither does a transform on it");

  CGColorRelease(red);
  CGContextRelease(context);
}

static void nothingToDraw(void)
{
  CGColorRef red = opaque(1, 0, 0);
  CGContextRef context = newContext();
  CALayer *bare = [CALayer layer];

  [bare setFrame: CGRectMake(10, 20, 30, 40)];
  [bare renderInContext: context];
  PASS(paintedCount(context) == 0,
       "a layer with no colour and no contents paints nothing");
  CGContextRelease(context);

  context = newContext();
  CALayer *hidden = [CALayer layer];
  [hidden setFrame: CGRectMake(10, 20, 30, 40)];
  [hidden setBackgroundColor: red];
  [hidden setHidden: YES];
  [hidden renderInContext: context];
  PASS(paintedCount(context) == 0, "a hidden layer paints nothing");
  CGContextRelease(context);

  context = newContext();
  CALayer *clear = [CALayer layer];
  [clear setFrame: CGRectMake(10, 20, 30, 40)];
  [clear setBackgroundColor: red];
  [clear setOpacity: 0.0];
  [clear renderInContext: context];
  PASS(paintedCount(context) == 0, "and neither does one at zero opacity");
  CGContextRelease(context);

  context = newContext();
  CALayer *half = [CALayer layer];
  [half setFrame: CGRectMake(10, 20, 30, 40)];
  [half setBackgroundColor: red];
  [half setOpacity: 0.5];
  [half renderInContext: context];
  PASS(paintedCount(context) == 30 * 40,
       "one at half opacity paints the same area");
  PASS(!fullyPainted(context), "but no part of it at full strength");

  CGColorRelease(red);
  CGContextRelease(context);
}

static void sublayers(void)
{
  CGColorRef red = opaque(1, 0, 0);
  CGColorRef blue = opaque(0, 0, 1);
  CGContextRef context = newContext();
  CALayer *parent = [CALayer layer];
  CALayer *child = [CALayer layer];

  [parent setFrame: CGRectMake(10, 10, 40, 40)];
  [parent setBackgroundColor: red];
  [child setFrame: CGRectMake(5, 5, 10, 10)];
  [child setBackgroundColor: blue];
  [parent addSublayer: child];
  [parent renderInContext: context];
  PASS(paintedExactly(context, 0, 0, 40, 40),
       "a sublayer inside its superlayer adds nothing to what is painted");
  CGContextRelease(context);

  /* A sublayer is placed by its own frame, so it can fall outside. */
  context = newContext();
  CALayer *p = [CALayer layer];
  CALayer *k = [CALayer layer];
  [p setFrame: CGRectMake(10, 10, 20, 20)];
  [k setFrame: CGRectMake(10, 10, 20, 20)];
  [k setBackgroundColor: red];
  [p addSublayer: k];
  [p renderInContext: context];
  PASS(paintedExactly(context, 10, 10, 30, 30),
       "a sublayer outside its superlayer is still drawn");
  CGContextRelease(context);

  context = newContext();
  [p setMasksToBounds: YES];
  [p renderInContext: context];
  PASS(paintedExactly(context, 10, 10, 20, 20),
       "unless the superlayer masks to its bounds, which cuts it down");
  CGContextRelease(context);

  context = newContext();
  CALayer *hp = [CALayer layer];
  CALayer *hk = [CALayer layer];
  [hp setFrame: CGRectMake(0, 0, 100, 100)];
  [hk setFrame: CGRectMake(10, 10, 20, 20)];
  [hk setBackgroundColor: red];
  [hk setHidden: YES];
  [hp addSublayer: hk];
  [hp renderInContext: context];
  PASS(paintedCount(context) == 0, "a hidden sublayer is left out too");
  CGContextRelease(context);

  /* The last sublayer added is drawn over the ones before it. */
  context = newContext();
  CGContextRef alone = newContext();
  CALayer *op = [CALayer layer];
  CALayer *first = [CALayer layer];
  CALayer *second = [CALayer layer];
  [op setFrame: CGRectMake(0, 0, 100, 100)];
  [first setFrame: CGRectMake(10, 10, 20, 20)];
  [first setBackgroundColor: red];
  [second setFrame: CGRectMake(10, 10, 20, 20)];
  [second setBackgroundColor: blue];
  [op addSublayer: first];
  [op addSublayer: second];
  [op renderInContext: context];

  CALayer *ap = [CALayer layer];
  CALayer *only = [CALayer layer];
  [ap setFrame: CGRectMake(0, 0, 100, 100)];
  [only setFrame: CGRectMake(10, 10, 20, 20)];
  [only setBackgroundColor: blue];
  [ap addSublayer: only];
  [ap renderInContext: alone];

  PASS(memcmp((unsigned char *)CGBitmapContextGetData(context)
              + ((SIDE - 1 - 15) * SIDE + 15) * 4,
              (unsigned char *)CGBitmapContextGetData(alone)
              + ((SIDE - 1 - 15) * SIDE + 15) * 4, 4) == 0,
       "where two sublayers overlap, the one added later is on top");

  CGContextRelease(context);
  CGContextRelease(alone);
  CGColorRelease(red);
  CGColorRelease(blue);
}

static void theBoundsOrigin(void)
{
  CGColorRef red = opaque(1, 0, 0);
  CGContextRef context = newContext();
  CALayer *parent = [CALayer layer];
  CALayer *child = [CALayer layer];

  [parent setFrame: CGRectMake(0, 0, 60, 60)];
  [parent setBounds: CGRectMake(10, 10, 60, 60)];
  [child setFrame: CGRectMake(10, 10, 20, 20)];
  [child setBackgroundColor: red];
  [parent addSublayer: child];
  [parent renderInContext: context];
  PASS(paintedExactly(context, 10, 10, 30, 30),
       "the bounds origin of the layer that was asked does not move its "
       "sublayers");
  CGContextRelease(context);

  /* One further down does move them. */
  context = newContext();
  CALayer *root = [CALayer layer];
  CALayer *middle = [CALayer layer];
  CALayer *leaf = [CALayer layer];
  [root setFrame: CGRectMake(0, 0, 100, 100)];
  [middle setFrame: CGRectMake(0, 0, 60, 60)];
  [middle setBounds: CGRectMake(10, 10, 60, 60)];
  [leaf setFrame: CGRectMake(10, 10, 20, 20)];
  [leaf setBackgroundColor: red];
  [middle addSublayer: leaf];
  [root addSublayer: middle];
  [root renderInContext: context];
  PASS(paintedExactly(context, 0, 0, 20, 20),
       "a bounds origin below that one does move them");

  CGColorRelease(red);
  CGContextRelease(context);
}

static void sublayerPlacement(void)
{
  CGColorRef red = opaque(1, 0, 0);
  CGContextRef context = newContext();
  CALayer *p = [CALayer layer];
  CALayer *k = [CALayer layer];

  [p setFrame: CGRectMake(0, 0, 100, 100)];
  [k setFrame: CGRectMake(10, 10, 20, 20)];
  [k setBackgroundColor: red];
  [k setTransform: CATransform3DMakeTranslation(30, 0, 0)];
  [p addSublayer: k];
  [p renderInContext: context];
  PASS(paintedExactly(context, 40, 10, 60, 30),
       "a transform on a sublayer does move it");
  CGContextRelease(context);

  context = newContext();
  CALayer *ap = [CALayer layer];
  CALayer *ak = [CALayer layer];
  [ap setFrame: CGRectMake(0, 0, 100, 100)];
  [ak setBounds: CGRectMake(0, 0, 20, 20)];
  [ak setPosition: CGPointMake(50, 50)];
  [ak setAnchorPoint: CGPointMake(0, 0)];
  [ak setBackgroundColor: red];
  [ap addSublayer: ak];
  [ap renderInContext: context];
  PASS(paintedExactly(context, 50, 50, 70, 70),
       "a sublayer anchored at its corner sits with that corner on its "
       "position");
  CGContextRelease(context);

  context = newContext();
  CALayer *cp = [CALayer layer];
  CALayer *ck = [CALayer layer];
  [cp setFrame: CGRectMake(0, 0, 100, 100)];
  [ck setBounds: CGRectMake(0, 0, 20, 20)];
  [ck setPosition: CGPointMake(50, 50)];
  [ck setBackgroundColor: red];
  [cp addSublayer: ck];
  [cp renderInContext: context];
  PASS(paintedExactly(context, 40, 40, 60, 60),
       "and one anchored at its centre sits around it");
  CGContextRelease(context);

  context = newContext();
  CALayer *sp = [CALayer layer];
  CALayer *sk = [CALayer layer];
  [sp setFrame: CGRectMake(0, 0, 100, 100)];
  [sk setFrame: CGRectMake(10, 10, 20, 20)];
  [sk setBackgroundColor: red];
  [sp addSublayer: sk];
  [sp setSublayerTransform: CATransform3DMakeTranslation(30, 0, 0)];
  [sp renderInContext: context];
  PASS(paintedExactly(context, 40, 10, 60, 30),
       "a sublayer transform moves the sublayers under it");

  CGColorRelease(red);
  CGContextRelease(context);
}

@interface Painter : NSObject
@end

@implementation Painter
- (void) drawLayer: (CALayer *)layer inContext: (CGContextRef)context
{
  CGColorRef green = CGColorCreateGenericRGB(0, 1, 0, 1);

  CGContextSetFillColorWithColor(context, green);
  CGContextFillRect(context, CGRectMake(0, 0, 10, 10));
  CGColorRelease(green);
}
@end

static void whatTheDelegateDrew(void)
{
  CGContextRef context = newContext();
  CALayer *l = [CALayer layer];
  Painter *painter = [[Painter new] autorelease];

  [l setFrame: CGRectMake(0, 0, 40, 40)];
  [l setDelegate: painter];
  [l renderInContext: context];
  PASS(paintedCount(context) == 0,
       "a layer that was never displayed paints nothing, since rendering "
       "does not ask the delegate to draw");
  CGContextRelease(context);

  context = newContext();
  [l display];
  [l renderInContext: context];
  PASS(paintedExactly(context, 0, 0, 10, 10),
       "once it has been displayed, what the delegate drew is what appears");

  CGContextRelease(context);
}

static void nothingBadHappens(void)
{
  CALayer *l = [CALayer layer];

  [l setFrame: CGRectMake(0, 0, 10, 10)];
  PASS_RUNS([l renderInContext: NULL],
            "rendering into no context at all is not an error");
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("rendering a layer tree into a context")

  whereTheLayerLands();
  nothingToDraw();
  sublayers();
  theBoundsOrigin();
  sublayerPlacement();
  whatTheDelegateDrew();
  nothingBadHappens();

  END_SET("rendering a layer tree into a context")

  [pool release];
  return 0;
}
