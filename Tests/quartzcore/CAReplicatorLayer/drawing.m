/* What a replicator layer draws when it is rendered into a context.  The
   expected values were measured against Apple QuartzCore with a 20 by 20
   sublayer in a 100 by 100 replicator at the origin of a 200 by 100 context.

   Apple's -renderInContext: repeats the sublayers only.  instanceColor and
   the four colour offsets have no effect there, so no colour is asserted.  A
   scale in instanceTransform is applied about the layer's origin and puts the
   second copy outside the context, so a translation is used here. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CAReplicatorLayer.h>
#import <CoreGraphics/CoreGraphics.h>
#include <string.h>

#define W 200
#define H 100

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

/* The box of everything painted.  Answers NO where nothing was. */
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

static CAReplicatorLayer *replicator(int count, CATransform3D t)
{
  CAReplicatorLayer *r = [CAReplicatorLayer layer];

  [r setBounds: CGRectMake(0, 0, 100, 100)];
  [r addSublayer: redChild()];
  [r setInstanceCount: count];
  [r setInstanceTransform: t];
  return r;
}

static void oneInstanceIsJustTheChild(void)
{
  CGContextRef context = newContext();
  int x0, y0, x1, y1;

  [replicator(1, CATransform3DIdentity) renderInContext: context];
  PASS(paintedBox(context, &x0, &y0, &x1, &y1),
       "a replicator with one instance draws its sublayer");
  PASS(x1 < 25, "and no wider than that sublayer");
  CGContextRelease(context);
}

static void everyInstanceIsDrawn(void)
{
  CGContextRef one = newContext();
  CGContextRef three = newContext();
  int ax0, ay0, ax1, ay1, bx0, by0, bx1, by1;

  [replicator(1, CATransform3DMakeTranslation(30, 0, 0))
    renderInContext: one];
  [replicator(3, CATransform3DMakeTranslation(30, 0, 0))
    renderInContext: three];
  paintedBox(one, &ax0, &ay0, &ax1, &ay1);
  paintedBox(three, &bx0, &by0, &bx1, &by1);

  PASS(paintedCount(three) > paintedCount(one),
       "three instances cover more than one");
  PASS(bx1 > ax1 + 50,
       "and the third instance is two offsets further across");
  PASS(bx0 == ax0, "while the first is where one instance was");
  CGContextRelease(one);
  CGContextRelease(three);
}

static void zeroInstancesDrawNothing(void)
{
  CGContextRef context = newContext();

  [replicator(0, CATransform3DIdentity) renderInContext: context];
  PASS(paintedCount(context) == 0,
       "a replicator with no instances draws nothing");
  CGContextRelease(context);
}

/* Only the sublayers are repeated. */
static void theBackgroundIsNotRepeated(void)
{
  CGContextRef context = newContext();
  CAReplicatorLayer *r = [CAReplicatorLayer layer];
  CGColorRef green = opaque(0, 1, 0);

  [r setBounds: CGRectMake(0, 0, 40, 40)];
  [r setBackgroundColor: green];
  [r addSublayer: redChild()];
  [r setInstanceCount: 3];
  [r setInstanceTransform: CATransform3DMakeTranslation(60, 0, 0)];
  [r renderInContext: context];

  PASS(painted(context, 30, 30), "a replicator draws its own background");
  PASS(painted(context, 130, 10),
       "and repeats its sublayers past its own bounds");
  PASS(!painted(context, 90, 30),
       "while its background is drawn once, not once per instance");

  CGColorRelease(green);
  CGContextRelease(context);
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what a replicator layer draws")

  oneInstanceIsJustTheChild();
  everyInstanceIsDrawn();
  zeroInstancesDrawNothing();
  theBackgroundIsNotRepeated();

  END_SET("what a replicator layer draws")

  [pool release];
  return 0;
}
