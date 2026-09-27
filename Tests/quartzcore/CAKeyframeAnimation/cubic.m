/* A keyframe animation that draws a curve through its values.

   Apple documents what tension, continuity and bias mean: they belong to the
   cubic modes, they are given one per keyframe, and a keyframe without one
   uses zero.  The expected numbers below are worked out from the curve those
   describe rather than read back from the framework.

   The first and last values have nothing before or after them, so the value
   itself stands in for what is missing, which is what gives the curve its
   ends.  The numbers below are worked out from that.

   Take the values 0, 1 and 0.  Half way along the first stretch a straight
   line is at 0.5.  The curve leaves the first value at half the step to the
   second, and arrives at the second with no slope at all, the values either
   side of it being equal; half way along that is 0.5625.  With the tension
   at 1 there is no slope at either end and it is back at 0.5.

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

#define CLOSE(a, b) (fabs((double)(a) - (double)(b)) < 1e-4)

static NSNumber *
number(float value)
{
  return [NSNumber numberWithFloat: value];
}

static NSArray *
numbers(float a, float b, float c)
{
  return [NSArray arrayWithObjects: number(a), number(b), number(c), nil];
}

static float
valueAt(CAKeyframeAnimation *k, CFTimeInterval time, CALayer *layer)
{
  return [[k calculatedAnimationValueAtTime: time onLayer: layer] floatValue];
}

/* Up to one and back down again, over four seconds. */
static CAKeyframeAnimation *
overAndBack(NSString *mode)
{
  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"opacity"];

  [k setDuration: 4.0];
  [k setValues: numbers(0.0, 1.0, 0.0)];
  [k setCalculationMode: mode];
  return k;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the values a curve is drawn through")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k = overAndBack(kCAAnimationCubic);

  PASS(CLOSE(valueAt(k, 0.0, layer), 0.0), "it starts at the first value");
  PASS(CLOSE(valueAt(k, 2.0, layer), 1.0), "it passes through the second");
  PASS(CLOSE(valueAt(k, 4.0, layer), 0.0), "and ends at the last");

  END_SET("the values a curve is drawn through")

  START_SET("the curve between two values")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *straight = overAndBack(kCAAnimationLinear);
  CAKeyframeAnimation *curved = overAndBack(kCAAnimationCubic);

  PASS(CLOSE(valueAt(straight, 1.0, layer), 0.5),
       "a straight line is half way up half way along");
  PASS(CLOSE(valueAt(curved, 1.0, layer), 0.5625),
       "and the curve is above it, arriving at the second value level");

  END_SET("the curve between two values")

  START_SET("tension")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k = overAndBack(kCAAnimationCubic);

  [k setTensionValues: numbers(1.0, 1.0, 1.0)];
  PASS(CLOSE(valueAt(k, 1.0, layer), 0.5),
       "a tension of one takes the slope out of both ends");
  PASS(CLOSE(valueAt(k, 2.0, layer), 1.0),
       "and the curve still passes through the values");

  END_SET("tension")

  START_SET("a shape value that was not given")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k = overAndBack(kCAAnimationCubic);
  CAKeyframeAnimation *none = overAndBack(kCAAnimationCubic);

  /* One entry for the first keyframe only; the rest are zero, which is what
     an animation with no tension at all uses. */
  [k setTensionValues: [NSArray arrayWithObject: number(0.0)]];

  PASS(CLOSE(valueAt(k, 1.0, layer), valueAt(none, 1.0, layer)),
       "a keyframe with no tension of its own is drawn as if it were zero");

  END_SET("a shape value that was not given")

  START_SET("continuity and bias")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *plain = overAndBack(kCAAnimationCubic);
  CAKeyframeAnimation *biased = overAndBack(kCAAnimationCubic);
  CAKeyframeAnimation *broken = overAndBack(kCAAnimationCubic);

  [biased setBiasValues: numbers(0.0, 1.0, 0.0)];
  [broken setContinuityValues: numbers(0.0, 1.0, 0.0)];

  PASS(!CLOSE(valueAt(biased, 1.0, layer), valueAt(plain, 1.0, layer)),
       "a bias at the second value changes the stretch before it");
  PASS(!CLOSE(valueAt(broken, 1.0, layer), valueAt(plain, 1.0, layer)),
       "and so does a continuity");
  PASS(CLOSE(valueAt(biased, 2.0, layer), 1.0),
       "neither moves the value the curve passes through");

  END_SET("continuity and bias")

  START_SET("a curve through points")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"position"];
  CGPoint first = CGPointMake(0, 0);
  CGPoint second = CGPointMake(10, 10);
  CGPoint third = CGPointMake(20, 0);
  CGPoint value = CGPointMake(-1, -1);

  [k setDuration: 4.0];
  [k setValues: [NSArray arrayWithObjects:
    [NSValue valueWithBytes: &first objCType: @encode(CGPoint)],
    [NSValue valueWithBytes: &second objCType: @encode(CGPoint)],
    [NSValue valueWithBytes: &third objCType: @encode(CGPoint)], nil]];
  [k setCalculationMode: kCAAnimationCubic];

  [[k calculatedAnimationValueAtTime: 1.0 onLayer: layer] getValue: &value];
  PASS(CLOSE(value.x, 4.375), "a point is curved through each way at once");
  PASS(CLOSE(value.y, 5.625),
       "the two ways being curved apart, since what lies either side differs");

  [[k calculatedAnimationValueAtTime: 2.0 onLayer: layer] getValue: &value];
  PASS(CLOSE(value.x, 10.0) && CLOSE(value.y, 10.0),
       "and the curve passes through the point it was given");

  END_SET("a curve through points")

  START_SET("values a curve cannot be drawn through")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"transform"];
  CATransform3D first = CATransform3DIdentity;
  CATransform3D second = CATransform3DMakeScale(2, 2, 2);
  CATransform3D third = CATransform3DMakeScale(3, 3, 3);
  CATransform3D value = CATransform3DIdentity;

  [k setDuration: 4.0];
  [k setValues: [NSArray arrayWithObjects:
    [NSValue valueWithBytes: &first objCType: @encode(CATransform3D)],
    [NSValue valueWithBytes: &second objCType: @encode(CATransform3D)],
    [NSValue valueWithBytes: &third objCType: @encode(CATransform3D)], nil]];
  [k setCalculationMode: kCAAnimationCubic];

  [[k calculatedAnimationValueAtTime: 1.0 onLayer: layer] getValue: &value];
  PASS(CLOSE(value.m11, 1.5),
       "a transform goes straight from one value to the next, as before");

  END_SET("values a curve cannot be drawn through")

  [pool release];
  return 0;
}
