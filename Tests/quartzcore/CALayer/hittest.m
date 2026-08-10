/* Asking a layer whether a point is inside it, and which layer is under a
   point.  Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("whether a point is inside a layer")

  CALayer *l = [CALayer layer];

  [l setBounds: CGRectMake(0, 0, 100, 100)];
  [l setPosition: CGPointMake(500, 500)];

  PASS([l containsPoint: CGPointMake(0, 0)] == YES,
       "the corner of the bounds is inside");
  PASS([l containsPoint: CGPointMake(99.9, 99.9)] == YES,
       "just short of the far corner is inside");
  PASS([l containsPoint: CGPointMake(100, 100)] == NO,
       "the far corner itself is not");
  PASS([l containsPoint: CGPointMake(-0.1, 50)] == NO,
       "just outside is not");
  PASS([l containsPoint: CGPointMake(500, 500)] == NO,
       "the point is measured against the bounds, not the position");

  CALayer *shifted = [CALayer layer];

  [shifted setBounds: CGRectMake(10, 10, 100, 100)];
  PASS([shifted containsPoint: CGPointMake(5, 5)] == NO,
       "a bounds origin moves what counts as inside");
  PASS([shifted containsPoint: CGPointMake(15, 15)] == YES,
       "so a point past that origin is inside");
  PASS([shifted containsPoint: CGPointMake(109, 109)] == YES,
       "and the far edge moves with it");

  END_SET("whether a point is inside a layer")

  START_SET("which layer is under a point")

  CALayer *root = [CALayer layer];
  CALayer *child = [CALayer layer];

  [root setBounds: CGRectMake(0, 0, 100, 100)];
  [root setPosition: CGPointMake(50, 50)];
  [child setBounds: CGRectMake(0, 0, 20, 20)];
  [child setPosition: CGPointMake(50, 50)];
  [root addSublayer: child];

  PASS([root hitTest: CGPointMake(50, 50)] == child,
       "a point over the sublayer finds the sublayer");
  PASS([root hitTest: CGPointMake(5, 5)] == root,
       "a point away from it finds the layer itself");
  PASS([root hitTest: CGPointMake(500, 500)] == nil,
       "a point outside finds nothing");
  PASS([root hitTest: CGPointMake(100, 100)] == nil,
       "and the far edge is outside");

  END_SET("which layer is under a point")

  START_SET("two sublayers over each other")

  CALayer *root = [CALayer layer];
  CALayer *lower = [CALayer layer];
  CALayer *upper = [CALayer layer];

  [root setBounds: CGRectMake(0, 0, 100, 100)];
  [root setPosition: CGPointMake(50, 50)];
  [lower setBounds: CGRectMake(0, 0, 40, 40)];
  [lower setPosition: CGPointMake(50, 50)];
  [upper setBounds: CGRectMake(0, 0, 40, 40)];
  [upper setPosition: CGPointMake(50, 50)];
  [root addSublayer: lower];
  [root addSublayer: upper];

  PASS([root hitTest: CGPointMake(50, 50)] == upper,
       "the one added last is the one found");

  [upper setHidden: YES];
  PASS([root hitTest: CGPointMake(50, 50)] == lower,
       "a hidden layer is passed over");
  [upper setHidden: NO];

  [lower setZPosition: 10];
  PASS([root hitTest: CGPointMake(50, 50)] == lower,
       "a higher z position lifts a layer above the one added after it");

  END_SET("two sublayers over each other")

  START_SET("a sublayer hanging outside its superlayer")

  CALayer *root = [CALayer layer];
  CALayer *child = [CALayer layer];

  [root setBounds: CGRectMake(0, 0, 100, 100)];
  [root setPosition: CGPointMake(50, 50)];
  [child setBounds: CGRectMake(0, 0, 20, 20)];
  [child setPosition: CGPointMake(150, 150)];
  [root addSublayer: child];

  PASS([root hitTest: CGPointMake(150, 150)] == child,
       "a sublayer outside its superlayer is still found");

  [root setMasksToBounds: YES];
  PASS([root hitTest: CGPointMake(150, 150)] == nil,
       "unless the superlayer masks what falls outside it");

  END_SET("a sublayer hanging outside its superlayer")

  START_SET("a layer on its own")

  CALayer *lone = [CALayer layer];

  [lone setBounds: CGRectMake(0, 0, 100, 100)];
  [lone setPosition: CGPointMake(50, 50)];

  PASS([lone hitTest: CGPointMake(50, 50)] == lone,
       "a point inside the frame of a layer with no superlayer finds it");
  PASS([lone hitTest: CGPointMake(500, 500)] == nil,
       "and a point outside finds nothing");

  END_SET("a layer on its own")

  [pool release];
  return 0;
}
