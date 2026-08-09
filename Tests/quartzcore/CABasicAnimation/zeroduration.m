/* The value an animation calculates when its duration is zero.

   An animation starts with a duration of zero, and a layer gives one it is
   handed the duration of the current transaction.  An animation that is
   asked for its value without being added to a layer keeps the zero, and
   dividing the time by it is what this file covers.

   -calculatedAnimationValueAtTime:onLayer: is GNUstep API with no
   counterpart in Apple QuartzCore, so this file is named in
   APPLE_SKIP_TESTS. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <math.h>

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CATransaction.h>

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

/* An opacity animation from 0 to 1 which is never given a duration. */
static CABasicAnimation *
animation(void)
{
  CABasicAnimation *b = [CABasicAnimation animationWithKeyPath: @"opacity"];

  [b setFromValue: number(0.0)];
  [b setToValue: number(1.0)];
  return b;
}

static float
valueAt(CABasicAnimation *b, CFTimeInterval time, CALayer *layer)
{
  return [[b calculatedAnimationValueAtTime: time onLayer: layer] floatValue];
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("an animation that was never given a duration")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = animation();

  PASS([b duration] == 0.0, "an animation starts with a duration of zero");

  PASS(CLOSE(valueAt(b, 0.0, layer), 1.0),
       "at the time it begins it is already at its end");
  PASS(CLOSE(valueAt(b, 1.0, layer), 1.0), "and it stays there");

  END_SET("an animation that was never given a duration")

  START_SET("a duration that is set to zero")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = animation();
  CABasicAnimation *negative = animation();

  [b setDuration: 0.0];
  PASS(CLOSE(valueAt(b, 0.5, layer), 1.0),
       "a duration of zero leaves no time to be part way through");

  [negative setDuration: -1.0];
  PASS(CLOSE(valueAt(negative, 0.5, layer), 1.0),
       "and neither does one below zero");

  END_SET("a duration that is set to zero")

  START_SET("a value that is not a number")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = [CABasicAnimation animationWithKeyPath: @"position"];
  CGPoint from = CGPointMake(0, 0);
  CGPoint to = CGPointMake(10, 20);
  NSValue *v;
  CGPoint p = CGPointMake(-1, -1);

  [b setFromValue: [NSValue valueWithBytes: &from objCType: @encode(CGPoint)]];
  [b setToValue: [NSValue valueWithBytes: &to objCType: @encode(CGPoint)]];
  v = [b calculatedAnimationValueAtTime: 0.5 onLayer: layer];
  if (v != nil)
    {
      [v getValue: &p];
    }

  PASS(CLOSE(p.x, 10.0) && CLOSE(p.y, 20.0),
       "a point ends up at the end of the animation as well");

  END_SET("a value that is not a number")

  START_SET("an animation a layer has been given")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = animation();

  [layer addAnimation: b forKey: @"opacity"];

  PASS(CLOSE([b duration], [CATransaction animationDuration]),
       "a layer gives an animation with no duration the transaction's");
  PASS(CLOSE(valueAt(b, [b duration] / 2.0, layer), 0.5),
       "so an animation that a layer runs is half way through half way along");

  END_SET("an animation a layer has been given")

  [pool release];
  return 0;
}
