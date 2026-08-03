/* The value a basic animation calculates part way through its duration, and
   what applying one to a layer does.

   -calculatedAnimationValueAtTime:onLayer: and -applyToLayer: are GNUstep
   API with no counterpart in Apple QuartzCore, so the expected values here
   are the ones this implementation produces rather than reference values.
   The file is named in APPLE_SKIP_TESTS for that reason.  Where Apple
   documents the surrounding behaviour, the documented behaviour is the
   expectation and the test is hopeful. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <math.h>
#include <string.h>

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAMediaTimingFunction.h>
#import <QuartzCore/CATransform3D.h>

/* Declared by the framework, not by a public header. */
@interface CAPropertyAnimation (Interpolation)
- (id) calculatedAnimationValueAtTime: (CFTimeInterval)theTime
                              onLayer: (CALayer *)layer;
- (void) applyToLayer: (CALayer *)layer;
@end

#define CLOSE(a, b) (fabs((double)(a) - (double)(b)) < 1e-4)

static CABasicAnimation *
animationFrom(id fromValue, id toValue, CFTimeInterval duration)
{
  CABasicAnimation *b = [CABasicAnimation animationWithKeyPath: @"opacity"];

  [b setDuration: duration];
  [b setFromValue: fromValue];
  [b setToValue: toValue];
  return b;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("interpolating between two numbers")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = animationFrom([NSNumber numberWithFloat: 0.0],
                                      [NSNumber numberWithFloat: 1.0], 2.0);
  id atStart = [b calculatedAnimationValueAtTime: 0.0 onLayer: layer];
  id atMiddle = [b calculatedAnimationValueAtTime: 1.0 onLayer: layer];
  id atEnd = [b calculatedAnimationValueAtTime: 2.0 onLayer: layer];

  PASS([atStart isKindOfClass: [NSNumber class]],
       "the value is a number when the two ends are numbers");
  PASS(CLOSE([atStart floatValue], 0.0), "it starts at the from value");
  PASS(CLOSE([atMiddle floatValue], 0.5),
       "half way through the duration it is half way between the two");
  PASS(CLOSE([atEnd floatValue], 1.0), "at the end it is the to value");

  END_SET("interpolating between two numbers")

  START_SET("time outside the duration")

  /* Neither end is held.  -[CALayer applyAnimationsAtTime:] is what stops
     asking once an animation is over, so the fraction is taken as given. */
  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = animationFrom([NSNumber numberWithFloat: 0.0],
                                      [NSNumber numberWithFloat: 1.0], 2.0);

  PASS(CLOSE([[b calculatedAnimationValueAtTime: 4.0 onLayer: layer] floatValue],
             2.0),
       "past the end the value carries on past the to value");
  PASS(CLOSE([[b calculatedAnimationValueAtTime: -1.0 onLayer: layer] floatValue],
             -0.5),
       "before the start it carries on past the from value");

  END_SET("time outside the duration")

  START_SET("a timing function shapes the fraction")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = animationFrom([NSNumber numberWithFloat: 0.0],
                                      [NSNumber numberWithFloat: 1.0], 2.0);
  float linear = [[b calculatedAnimationValueAtTime: 1.0 onLayer: layer] floatValue];

  [b setTimingFunction:
    [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn]];

  float easeIn = [[b calculatedAnimationValueAtTime: 1.0 onLayer: layer] floatValue];

  PASS(CLOSE(linear, 0.5), "with no timing function the fraction is the time");
  PASS(easeIn > 0.0 && easeIn < linear,
       "easing in is behind the straight line half way through");

  END_SET("a timing function shapes the fraction")

  START_SET("interpolating a point")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = animationFrom([NSValue valueWithPoint: NSMakePoint(0, 0)],
                                      [NSValue valueWithPoint: NSMakePoint(10, 20)],
                                      2.0);
  NSValue *v = [b calculatedAnimationValueAtTime: 1.0 onLayer: layer];
  CGPoint p = CGPointMake(-1, -1);

  PASS(v != nil && !strcmp([v objCType], @encode(CGPoint)),
       "the value is a point, whichever of the two point types went in");
  if (v != nil)
    {
      [v getValue: &p];
    }
  PASS(CLOSE(p.x, 5.0) && CLOSE(p.y, 10.0),
       "both of its members are half way between the two");

  END_SET("interpolating a point")

  START_SET("interpolating a size")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = animationFrom([NSValue valueWithSize: NSMakeSize(0, 0)],
                                      [NSValue valueWithSize: NSMakeSize(10, 20)],
                                      2.0);
  NSValue *v = [b calculatedAnimationValueAtTime: 1.0 onLayer: layer];
  CGSize s = CGSizeMake(-1, -1);

  PASS(v != nil && !strcmp([v objCType], @encode(CGSize)),
       "the value is a size, whichever of the two size types went in");
  if (v != nil)
    {
      [v getValue: &s];
    }

  testHopeful = YES;
  PASS(CLOSE(s.width, 5.0),
       "the width is half way between the two widths");
  PASS(!CLOSE(s.width, s.height),
       "the width and the height are worked out separately");
  testHopeful = NO;

  PASS(CLOSE(s.height, 10.0),
       "the height is half way between the two heights");

  END_SET("interpolating a size")

  START_SET("interpolating a rectangle")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = animationFrom([NSValue valueWithRect: NSMakeRect(0, 0, 0, 0)],
                                      [NSValue valueWithRect: NSMakeRect(10, 20, 30, 40)],
                                      2.0);
  NSValue *v = [b calculatedAnimationValueAtTime: 1.0 onLayer: layer];
  CGRect r = CGRectMake(-1, -1, -1, -1);

  PASS(v != nil && !strcmp([v objCType], @encode(CGRect)),
       "the value is a rectangle, whichever of the two rectangle types went in");
  if (v != nil)
    {
      [v getValue: &r];
    }
  PASS(CLOSE(r.origin.x, 5.0) && CLOSE(r.origin.y, 10.0),
       "its origin is half way between the two origins");
  PASS(CLOSE(r.size.width, 15.0) && CLOSE(r.size.height, 20.0),
       "its size is half way between the two sizes");

  END_SET("interpolating a rectangle")

  START_SET("interpolating a transform")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *b =
    animationFrom([NSValue valueWithCATransform3D: CATransform3DIdentity],
                  [NSValue valueWithCATransform3D:
                    CATransform3DMakeTranslation(10, 20, 30)], 2.0);
  CATransform3D t =
    [[b calculatedAnimationValueAtTime: 1.0 onLayer: layer] CATransform3DValue];

  PASS(CLOSE(t.m41, 5.0) && CLOSE(t.m42, 10.0) && CLOSE(t.m43, 15.0),
       "a translation is half made half way through");
  PASS(CLOSE(t.m11, 1.0) && CLOSE(t.m22, 1.0) && CLOSE(t.m33, 1.0),
       "and nothing is scaled by it");

  CABasicAnimation *c =
    animationFrom([NSValue valueWithCATransform3D: CATransform3DIdentity],
                  [NSValue valueWithCATransform3D:
                    CATransform3DMakeScale(2, 4, 8)], 2.0);
  CATransform3D s =
    [[c calculatedAnimationValueAtTime: 1.0 onLayer: layer] CATransform3DValue];

  PASS(CLOSE(s.m11, 1.5) && CLOSE(s.m22, 2.5) && CLOSE(s.m33, 4.5),
       "a scale is half made half way through");

  CABasicAnimation *d =
    animationFrom([NSValue valueWithCATransform3D: CATransform3DIdentity],
                  [NSValue valueWithCATransform3D: CATransform3DIdentity], 2.0);
  CATransform3D i =
    [[d calculatedAnimationValueAtTime: 1.0 onLayer: layer] CATransform3DValue];

  PASS(CATransform3DIsIdentity(i),
       "interpolating between one transform and itself leaves it alone");

  END_SET("interpolating a transform")

  START_SET("interpolating a colour")

  CALayer *layer = [CALayer layer];
  CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
  CGFloat black[4] = { 0, 0, 0, 1 };
  CGFloat white[4] = { 1, 1, 1, 1 };
  CGColorRef from = CGColorCreate(space, black);
  CGColorRef to = CGColorCreate(space, white);
  CABasicAnimation *b = animationFrom((id)from, (id)to, 2.0);
  CGColorRef v = (CGColorRef)[b calculatedAnimationValueAtTime: 1.0
                                                       onLayer: layer];

  PASS(v != NULL, "a colour is interpolated");
  if (v != NULL)
    {
      const CGFloat *c = CGColorGetComponents(v);

      PASS(CGColorGetNumberOfComponents(v) == 4,
           "the value has as many components as the two ends");
      PASS(CLOSE(c[0], 0.5) && CLOSE(c[1], 0.5) && CLOSE(c[2], 0.5),
           "each component is half way between the two");
      PASS(CLOSE(c[3], 1.0), "including the one both ends agree on");
    }
  CGColorRelease(from);
  CGColorRelease(to);
  CGColorSpaceRelease(space);

  END_SET("interpolating a colour")

  START_SET("ends that cannot be interpolated")

  CALayer *layer = [CALayer layer];

  PASS([animationFrom([NSNumber numberWithFloat: 0.0],
                      [NSValue valueWithPoint: NSMakePoint(1, 1)], 2.0)
         calculatedAnimationValueAtTime: 1.0 onLayer: layer] == nil,
       "two ends of different types give no value");
  PASS([animationFrom(@"one", @"another", 2.0)
         calculatedAnimationValueAtTime: 1.0 onLayer: layer] == nil,
       "two ends of a type that cannot be interpolated give no value");

  END_SET("ends that cannot be interpolated")

  START_SET("an end the animation was not given")

  /* Apple takes the missing end from the layer: an animation with only a
     from value runs to the layer's current value, one with only a to value
     runs from it, and a by value is added to it. */
  CALayer *layer = [CALayer layer];
  [layer setOpacity: 0.25];

  CABasicAnimation *from = animationFrom([NSNumber numberWithFloat: 0.0], nil, 2.0);
  CABasicAnimation *to = animationFrom(nil, [NSNumber numberWithFloat: 1.0], 2.0);
  CABasicAnimation *by = animationFrom([NSNumber numberWithFloat: 0.0], nil, 2.0);
  [by setByValue: [NSNumber numberWithFloat: 0.5]];

  testHopeful = YES;
  PASS(CLOSE([[from calculatedAnimationValueAtTime: 2.0 onLayer: layer] floatValue],
             0.25),
       "with only a from value it runs to the value the layer has");
  PASS(CLOSE([[to calculatedAnimationValueAtTime: 0.0 onLayer: layer] floatValue],
             0.25),
       "with only a to value it starts at the value the layer has");
  PASS(CLOSE([[by calculatedAnimationValueAtTime: 2.0 onLayer: layer] floatValue],
             0.5),
       "a by value is added to the from value");
  testHopeful = NO;

  END_SET("an end the animation was not given")

  START_SET("an animation with no duration")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = animationFrom([NSNumber numberWithFloat: 0.0],
                                      [NSNumber numberWithFloat: 1.0], 0.0);
  float atStart = [[b calculatedAnimationValueAtTime: 0.0 onLayer: layer] floatValue];
  float atEnd = [[b calculatedAnimationValueAtTime: 1.0 onLayer: layer] floatValue];

  testHopeful = YES;
  PASS(!isnan(atStart) && !isinf(atStart),
       "a duration of zero gives a number at the start");
  PASS(!isnan(atEnd) && !isinf(atEnd),
       "and a number after it");
  testHopeful = NO;

  END_SET("an animation with no duration")

  START_SET("an animation that interpolates nothing")

  CALayer *layer = [CALayer layer];
  CAPropertyAnimation *p = [CAPropertyAnimation animationWithKeyPath: @"opacity"];
  [p setDuration: 2.0];

  PASS([p calculatedAnimationValueAtTime: 1.0 onLayer: layer] == nil,
       "a property animation on its own calculates no value");

  CAKeyframeAnimation *k = [CAKeyframeAnimation animationWithKeyPath: @"opacity"];
  [k setDuration: 2.0];
  [k setValues: [NSArray arrayWithObjects: [NSNumber numberWithFloat: 0.0],
                                           [NSNumber numberWithFloat: 1.0], nil]];

  testHopeful = YES;
  PASS(CLOSE([[k calculatedAnimationValueAtTime: 1.0 onLayer: layer] floatValue],
             0.5),
       "a keyframe animation runs through the values it was given");
  testHopeful = NO;

  END_SET("an animation that interpolates nothing")

  START_SET("applying an animation to a layer")

  CALayer *layer = [CALayer layer];
  [layer setOpacity: 0.25];

  CABasicAnimation *b = animationFrom([NSNumber numberWithFloat: 0.0],
                                      [NSNumber numberWithFloat: 1.0], 4.0);
  [b setBeginTime: CACurrentMediaTime()];
  [b applyToLayer: layer];

  PASS([layer opacity] < 0.01,
       "applying an animation that has just begun writes its from value");

  CALayer *other = [CALayer layer];
  [other setOpacity: 0.25];

  CABasicAnimation *c = [CABasicAnimation animationWithKeyPath: @"opacity"];
  [c setDuration: 4.0];
  [c setBeginTime: CACurrentMediaTime()];
  [c applyToLayer: other];

  PASS(CLOSE([other opacity], 0.25),
       "applying one that calculates no value leaves the layer alone");

  END_SET("applying an animation to a layer")

  [pool release];
  return 0;
}
