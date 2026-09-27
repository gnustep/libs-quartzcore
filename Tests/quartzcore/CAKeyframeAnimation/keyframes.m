/* The value a keyframe animation calculates part way through its duration.

   -calculatedAnimationValueAtTime:onLayer: is GNUstep API with no counterpart
   in Apple QuartzCore, so this file is named in APPLE_SKIP_TESTS.  The
   properties it sets are Apple's and are checked in properties.m, which does
   run there. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <math.h>

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAMediaTimingFunction.h>

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

/* Three values, evenly spaced over four seconds unless told otherwise. */
static CAKeyframeAnimation *
keyframes(void)
{
  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"opacity"];

  [k setDuration: 4.0];
  [k setValues: [NSArray arrayWithObjects:
    number(0.0), number(1.0), number(0.0), nil]];
  return k;
}

static float
valueAt(CAKeyframeAnimation *k, CFTimeInterval time, CALayer *layer)
{
  return [[k calculatedAnimationValueAtTime: time onLayer: layer] floatValue];
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("running through the values")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k = keyframes();

  PASS(CLOSE(valueAt(k, 0.0, layer), 0.0), "it starts at the first value");
  PASS(CLOSE(valueAt(k, 1.0, layer), 0.5),
       "a quarter of the way along it is half way to the second");
  PASS(CLOSE(valueAt(k, 2.0, layer), 1.0),
       "half way along it is at the second value");
  PASS(CLOSE(valueAt(k, 3.0, layer), 0.5),
       "and then half way back down to the third");
  PASS(CLOSE(valueAt(k, 4.0, layer), 0.0), "ending at the last value");

  END_SET("running through the values")

  START_SET("one value and none")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"opacity"];

  [k setDuration: 4.0];

  PASS([k calculatedAnimationValueAtTime: 1.0 onLayer: layer] == nil,
       "an animation with no values calculates nothing");

  [k setValues: [NSArray arrayWithObject: number(0.75)]];

  PASS(CLOSE(valueAt(k, 1.0, layer), 0.75),
       "and one with a single value stays on it");

  END_SET("one value and none")

  START_SET("key times say where each value falls")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k = keyframes();

  /* The middle value now falls three quarters of the way along rather than
     half way. */
  [k setKeyTimes: [NSArray arrayWithObjects:
    number(0.0), number(0.75), number(1.0), nil]];

  PASS(CLOSE(valueAt(k, 3.0, layer), 1.0),
       "the second value falls where the key times put it");
  PASS(CLOSE(valueAt(k, 1.5, layer), 0.5),
       "half way to it is half the first value's share along");
  PASS(CLOSE(valueAt(k, 3.5, layer), 0.5),
       "and the last stretch is shorter to match");

  END_SET("key times say where each value falls")

  START_SET("a discrete animation does not interpolate")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k = keyframes();

  [k setCalculationMode: kCAAnimationDiscrete];

  /* Three values with no key times hold for a third of the duration each. */
  PASS(CLOSE(valueAt(k, 0.5, layer), 0.0), "it holds the first value");
  PASS(CLOSE(valueAt(k, 1.0, layer), 0.0),
       "still holding it a quarter of the way along, where interpolating "
       "would have reached half way");
  PASS(CLOSE(valueAt(k, 2.0, layer), 1.0), "then steps to the second");
  PASS(CLOSE(valueAt(k, 3.0, layer), 0.0), "and to the last");

  END_SET("a discrete animation does not interpolate")

  START_SET("the mode a keyframe animation starts in")

  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"opacity"];

  PASS([[k calculationMode] isEqualToString: kCAAnimationLinear],
       "it interpolates unless told otherwise");

  END_SET("the mode a keyframe animation starts in")

  START_SET("a timing function for each stretch")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k = keyframes();
  float straight = valueAt(k, 1.0, layer);

  /* One function, so it shapes the first stretch and the second is left as
     it was. */
  [k setTimingFunctions: [NSArray arrayWithObject:
    [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn]]];

  PASS(CLOSE(straight, 0.5), "without one the first stretch is a straight line");
  PASS(valueAt(k, 1.0, layer) < straight,
       "easing into the first stretch is behind it half way along");
  PASS(CLOSE(valueAt(k, 2.0, layer), 1.0),
       "and the stretch still ends where it did");

  END_SET("a timing function for each stretch")

  START_SET("time outside the duration")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k = keyframes();

  PASS(CLOSE(valueAt(k, 8.0, layer), 0.0),
       "past the end it holds the last value rather than running off it");
  PASS(CLOSE(valueAt(k, -1.0, layer), 0.0),
       "and before the start it holds the first");

  END_SET("time outside the duration")

  START_SET("a keyframe animation with no duration")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"opacity"];

  /* The values end somewhere other than they start, so that holding the
     last one can be told apart from holding the first. */
  [k setValues: [NSArray arrayWithObjects:
    number(0.0), number(0.25), number(1.0), nil]];
  [k setDuration: 0.0];

  PASS(CLOSE(valueAt(k, 1.0, layer), 1.0),
       "with no time to run through them it holds the last value");
  PASS(CLOSE(valueAt(k, 0.0, layer), 1.0),
       "and it holds it at the time it begins as well");

  END_SET("a keyframe animation with no duration")

  START_SET("values that are not numbers")

  CALayer *layer = [CALayer layer];
  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"position"];
  CGPoint first = CGPointMake(0, 0);
  CGPoint second = CGPointMake(10, 20);
  NSValue *v;
  CGPoint p = CGPointMake(-1, -1);

  [k setDuration: 2.0];
  [k setValues: [NSArray arrayWithObjects:
    [NSValue valueWithBytes: &first objCType: @encode(CGPoint)],
    [NSValue valueWithBytes: &second objCType: @encode(CGPoint)], nil]];
  v = [k calculatedAnimationValueAtTime: 1.0 onLayer: layer];
  if (v != nil)
    {
      [v getValue: &p];
    }

  PASS(CLOSE(p.x, 5.0) && CLOSE(p.y, 10.0),
       "points are interpolated between as a basic animation does");

  END_SET("values that are not numbers")

  [pool release];
  return 0;
}
