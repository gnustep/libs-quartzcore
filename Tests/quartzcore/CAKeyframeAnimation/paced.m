/* A keyframe animation that covers the same distance in each moment.

   Apple documents the contract this checks: a paced animation runs at a
   constant velocity, and the keyTimes are ignored while it does.  The values
   are therefore placed by the distance from one to the next rather than
   evenly, which is what tells a paced animation apart from a linear one.

   -calculatedAnimationValueAtTime:onLayer: is GNUstep API with no counterpart
   in Apple QuartzCore, so this file is named in APPLE_SKIP_TESTS. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <math.h>

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CAAnimation.h>

/* Declared by the framework, not by a public header. */
@interface CAPropertyAnimation (Interpolation)
- (id) calculatedAnimationValueAtTime: (CFTimeInterval)theTime
                              onLayer: (CALayer *)layer;
@end

#define CLOSE(a, b) (fabs((double)(a) - (double)(b)) < 1e-3)

static NSValue *
point(CGFloat x, CGFloat y)
{
  CGPoint p = CGPointMake(x, y);

  return [NSValue valueWithBytes: &p objCType: @encode(CGPoint)];
}

static CGPoint
pointAt(CAKeyframeAnimation *k, CFTimeInterval time, CALayer *layer)
{
  CGPoint p = CGPointMake(-1, -1);
  NSValue *value = [k calculatedAnimationValueAtTime: time onLayer: layer];

  if (value != nil)
    {
      [value getValue: &p];
    }
  return p;
}

static float
numberAt(CAKeyframeAnimation *k, CFTimeInterval time, CALayer *layer)
{
  return [[k calculatedAnimationValueAtTime: time onLayer: layer] floatValue];
}

/* Two steps of very different size: ten across, then a hundred. */
static CAKeyframeAnimation *
unevenPoints(void)
{
  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"position"];

  [k setDuration: 2.0];
  [k setValues: [NSArray arrayWithObjects:
    point(0, 0), point(10, 0), point(110, 0), nil]];
  return k;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("values spaced evenly when the animation is not paced")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k = unevenPoints();

  PASS(CLOSE(pointAt(k, 1.0, layer).x, 10),
       "half way along a linear animation is at the middle value, however "
       "far apart the values are");

  END_SET("values spaced evenly when the animation is not paced")

  START_SET("values spaced by distance when it is")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k = unevenPoints();

  [k setCalculationMode: kCAAnimationPaced];

  PASS(CLOSE(pointAt(k, 0.0, layer).x, 0), "it starts at the first value");
  PASS(CLOSE(pointAt(k, 1.0, layer).x, 55),
       "half way along it has covered half the distance, not half the values");
  PASS(CLOSE(pointAt(k, 2.0, layer).x, 110), "and it ends at the last");

  /* A tenth of the way is 11 of the 110 across, which is past the second
     value rather than a tenth of the way to it. */
  PASS(CLOSE(pointAt(k, 0.2, layer).x, 11),
       "and the pace is the same at either end of the middle value");

  END_SET("values spaced by distance when it is")

  START_SET("cubic pacing")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k = unevenPoints();

  [k setCalculationMode: kCAAnimationCubicPaced];

  /* Cubic pacing places the values by distance as pacing does, and then
     draws its curve through them, which moves the point a little off the
     straight line between the two it falls between. */
  PASS(fabs(pointAt(k, 1.0, layer).x - 55) < 1.5,
       "cubic pacing paces as well, its curve moving the point only a little");
  PASS(pointAt(k, 1.0, layer).x > 20,
       "and nowhere near where an animation that did not pace would put it");

  END_SET("cubic pacing")

  START_SET("the key times of a paced animation")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k = unevenPoints();

  [k setCalculationMode: kCAAnimationPaced];
  [k setKeyTimes: [NSArray arrayWithObjects:
    [NSNumber numberWithFloat: 0.0],
    [NSNumber numberWithFloat: 0.9],
    [NSNumber numberWithFloat: 1.0], nil]];

  PASS(CLOSE(pointAt(k, 1.0, layer).x, 55),
       "key times say nothing about a paced animation and are not read");

  END_SET("the key times of a paced animation")

  START_SET("pacing numbers")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"opacity"];

  [k setDuration: 2.0];
  [k setValues: [NSArray arrayWithObjects:
    [NSNumber numberWithFloat: 0.0],
    [NSNumber numberWithFloat: 1.0],
    [NSNumber numberWithFloat: 101.0], nil]];
  [k setCalculationMode: kCAAnimationPaced];

  PASS(CLOSE(numberAt(k, 1.0, layer), 50.5),
       "numbers are paced by how far apart they are");

  END_SET("pacing numbers")

  START_SET("values that cannot be measured")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"transform"];
  CATransform3D first = CATransform3DIdentity;
  CATransform3D second = CATransform3DMakeScale(2, 2, 2);
  CATransform3D third = CATransform3DMakeScale(3, 3, 3);
  CATransform3D value;

  [k setDuration: 2.0];
  [k setValues: [NSArray arrayWithObjects:
    [NSValue valueWithBytes: &first objCType: @encode(CATransform3D)],
    [NSValue valueWithBytes: &second objCType: @encode(CATransform3D)],
    [NSValue valueWithBytes: &third objCType: @encode(CATransform3D)], nil]];
  [k setCalculationMode: kCAAnimationPaced];

  value = CATransform3DIdentity;
  [[k calculatedAnimationValueAtTime: 1.0 onLayer: layer] getValue: &value];

  PASS(CLOSE(value.m11, 2.0),
       "a transform has no distance to pace by, so it is spaced evenly");

  END_SET("values that cannot be measured")

  START_SET("pacing along a path")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"position"];
  CGMutablePathRef path = CGPathCreateMutable();

  /* The same two uneven steps, as a path. */
  CGPathMoveToPoint(path, NULL, 0, 0);
  CGPathAddLineToPoint(path, NULL, 10, 0);
  CGPathAddLineToPoint(path, NULL, 110, 0);
  [k setDuration: 2.0];
  [k setPath: path];
  CGPathRelease(path);

  PASS(CLOSE(pointAt(k, 1.0, layer).x, 10),
       "an unpaced path gives each line the same length of time");

  [k setCalculationMode: kCAAnimationPaced];
  PASS(CLOSE(pointAt(k, 1.0, layer).x, 55),
       "a paced one gives each line time in proportion to its length");
  PASS(CLOSE(pointAt(k, 2.0, layer).x, 110), "and still ends at the end");

  END_SET("pacing along a path")

  START_SET("pacing along a curve")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"position"];
  CGMutablePathRef path = CGPathCreateMutable();
  CGPoint quarter, half, threeQuarters;
  float first, second, third, fourth;

  CGPathMoveToPoint(path, NULL, 0, 0);
  CGPathAddCurveToPoint(path, NULL, 0, 100, 100, 100, 100, 0);
  [k setDuration: 4.0];
  [k setPath: path];
  [k setCalculationMode: kCAAnimationPaced];
  CGPathRelease(path);

  quarter = pointAt(k, 1.0, layer);
  half = pointAt(k, 2.0, layer);
  threeQuarters = pointAt(k, 3.0, layer);

  PASS(CLOSE(half.x, 50), "half way along a symmetric curve is half way across");

  /* Each quarter of the time should cover about a quarter of the curve. */
  first = sqrt(quarter.x * quarter.x + quarter.y * quarter.y);
  second = sqrt((half.x - quarter.x) * (half.x - quarter.x)
                + (half.y - quarter.y) * (half.y - quarter.y));
  third = sqrt((threeQuarters.x - half.x) * (threeQuarters.x - half.x)
               + (threeQuarters.y - half.y) * (threeQuarters.y - half.y));
  fourth = sqrt((100 - threeQuarters.x) * (100 - threeQuarters.x)
                + threeQuarters.y * threeQuarters.y);

  PASS(fabs(first - second) < 2.0 && fabs(second - third) < 2.0
       && fabs(third - fourth) < 2.0,
       "and each quarter of the time covers about as much of the curve");

  END_SET("pacing along a curve")

  [pool release];
  return 0;
}
