/* The end a by value stands in for.

   Apple documents three of these: a from value and a by value interpolate
   between the from value and from plus by; a by value and a to value
   interpolate between to minus by and the to value; and a by value on its
   own works from the value the layer already has.

   -calculatedAnimationValueAtTime:onLayer: is GNUstep API with no
   counterpart in Apple QuartzCore, so this file is named in
   APPLE_SKIP_TESTS. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <math.h>
#include <string.h>

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CAAnimation.h>

/* Declared by the framework, not by a public header. */
@interface CAPropertyAnimation (Interpolation)
- (id) calculatedAnimationValueAtTime: (CFTimeInterval)theTime
                              onLayer: (CALayer *)layer;
@end

#define CLOSE(a, b) (fabs((double)(a) - (double)(b)) < 1e-4)

static CABasicAnimation *
animation(NSString *keyPath, id fromValue, id toValue, id byValue)
{
  CABasicAnimation *b = [CABasicAnimation animationWithKeyPath: keyPath];

  [b setDuration: 2.0];
  [b setFromValue: fromValue];
  [b setToValue: toValue];
  [b setByValue: byValue];
  return b;
}

static NSNumber *
number(float value)
{
  return [NSNumber numberWithFloat: value];
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("a from value and a by value")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = animation(@"opacity", number(0.25), nil, number(0.5));

  PASS(CLOSE([[b calculatedAnimationValueAtTime: 0.0 onLayer: layer] floatValue],
             0.25),
       "it starts at the from value");
  PASS(CLOSE([[b calculatedAnimationValueAtTime: 1.0 onLayer: layer] floatValue],
             0.5),
       "half way along it is half the by value past it");
  PASS(CLOSE([[b calculatedAnimationValueAtTime: 2.0 onLayer: layer] floatValue],
             0.75),
       "and it ends at the from value plus the by value");

  END_SET("a from value and a by value")

  START_SET("a by value and a to value")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = animation(@"opacity", nil, number(0.75), number(0.5));

  PASS(CLOSE([[b calculatedAnimationValueAtTime: 0.0 onLayer: layer] floatValue],
             0.25),
       "it starts at the to value less the by value");
  PASS(CLOSE([[b calculatedAnimationValueAtTime: 2.0 onLayer: layer] floatValue],
             0.75),
       "and ends at the to value");

  END_SET("a by value and a to value")

  START_SET("a by value on its own")

  /* The value it works from is the one the layer holds, which a layer only
     answers for when it is standing in for another. */
  CALayer *layer = [CALayer layer];
  CALayer *presentation;

  [layer setOpacity: 0.25];
  presentation = [layer presentationLayer];

  CABasicAnimation *b = animation(@"opacity", nil, nil, number(0.5));

  PASS(CLOSE([[b calculatedAnimationValueAtTime: 0.0 onLayer: presentation]
               floatValue], 0.25),
       "it starts at the value the layer already has");
  PASS(CLOSE([[b calculatedAnimationValueAtTime: 2.0 onLayer: presentation]
               floatValue], 0.75),
       "and ends the by value past it");

  END_SET("a by value on its own")

  START_SET("a by value that is a point")

  CALayer *layer = [CALayer layer];
  CGPoint from = CGPointMake(10, 20);
  CGPoint by = CGPointMake(4, 8);
  CABasicAnimation *b =
    animation(@"position",
              [NSValue valueWithBytes: &from objCType: @encode(CGPoint)],
              nil,
              [NSValue valueWithBytes: &by objCType: @encode(CGPoint)]);
  NSValue *v = [b calculatedAnimationValueAtTime: 2.0 onLayer: layer];
  CGPoint p = CGPointMake(-1, -1);

  PASS(v != nil && !strcmp([v objCType], @encode(CGPoint)),
       "the value is a point");
  if (v != nil)
    {
      [v getValue: &p];
    }
  PASS(CLOSE(p.x, 14) && CLOSE(p.y, 28),
       "with the by value added to both members");

  END_SET("a by value that is a point")

  START_SET("a by value that is a size")

  CALayer *layer = [CALayer layer];
  CGSize from = CGSizeMake(10, 20);
  CGSize by = CGSizeMake(4, 8);
  CABasicAnimation *b =
    animation(@"bounds",
              [NSValue valueWithBytes: &from objCType: @encode(CGSize)],
              nil,
              [NSValue valueWithBytes: &by objCType: @encode(CGSize)]);
  NSValue *v = [b calculatedAnimationValueAtTime: 2.0 onLayer: layer];
  CGSize s = CGSizeMake(-1, -1);

  if (v != nil)
    {
      [v getValue: &s];
    }
  /* The by value is added to both members, and then the interpolation
     between the two sizes takes the height of neither: every size comes out
     square, which is a separate matter from the by value. */
  testHopeful = YES;
  PASS(CLOSE(s.width, 14) && CLOSE(s.height, 28),
       "both members of a size take the by value");
  testHopeful = NO;

  END_SET("a by value that is a size")

  START_SET("a by value that is a rectangle")

  CALayer *layer = [CALayer layer];
  CGRect from = CGRectMake(1, 2, 10, 20);
  CGRect by = CGRectMake(3, 4, 5, 6);
  CABasicAnimation *b =
    animation(@"bounds",
              [NSValue valueWithBytes: &from objCType: @encode(CGRect)],
              nil,
              [NSValue valueWithBytes: &by objCType: @encode(CGRect)]);
  NSValue *v = [b calculatedAnimationValueAtTime: 2.0 onLayer: layer];
  CGRect r = CGRectMake(-1, -1, -1, -1);

  if (v != nil)
    {
      [v getValue: &r];
    }
  PASS(CLOSE(r.origin.x, 4) && CLOSE(r.origin.y, 6)
       && CLOSE(r.size.width, 15) && CLOSE(r.size.height, 26),
       "all four members of a rectangle take the by value");

  END_SET("a by value that is a rectangle")

  START_SET("a by value that cannot be added")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = animation(@"opacity", @"a string", nil, @"another");

  PASS([b calculatedAnimationValueAtTime: 1.0 onLayer: layer] == nil,
       "a by value of a type that cannot be added leaves nothing to animate");

  CATransform3D identity = CATransform3DIdentity;
  CABasicAnimation *t =
    animation(@"transform",
              [NSValue valueWithCATransform3D: identity], nil,
              [NSValue valueWithCATransform3D: identity]);

  PASS([t calculatedAnimationValueAtTime: 1.0 onLayer: layer] == nil,
       "and a transform is one of those types");

  END_SET("a by value that cannot be added")

  START_SET("a by value alongside both ends")

  /* Apple says no more than two of the three should be given.  Where all
     three are, the two ends are what count. */
  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = animation(@"opacity", number(0.0), number(1.0),
                                  number(0.25));

  PASS(CLOSE([[b calculatedAnimationValueAtTime: 2.0 onLayer: layer] floatValue],
             1.0),
       "the to value is where it ends, not the from value plus the by value");

  END_SET("a by value alongside both ends")

  [pool release];
  return 0;
}
