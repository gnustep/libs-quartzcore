/* The CAMediaTiming properties a layer and an animation start with, what
   their setters keep, and converting a time between layers.
   Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <math.h>

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAMediaTiming.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the timing a layer starts with")

  CALayer *l = [CALayer layer];

  PASS([l beginTime] == 0.0, "a layer begins at 0");
  PASS([l timeOffset] == 0.0, "a layer has no time offset");
  PASS([l repeatDuration] == 0.0, "a layer has no repeat duration");
  PASS([l autoreverses] == NO, "a layer does not autoreverse");
  PASS(isinf([l duration]), "a layer's duration is infinite");
  PASS([l speed] == 1.0, "a layer runs at speed 1");

  testHopeful = YES;
  PASS([l repeatCount] == 0.0, "a layer has a repeat count of 0");
  PASS([[l fillMode] isEqualToString: kCAFillModeRemoved],
       "a layer's fill mode is removed");
  testHopeful = NO;

  END_SET("the timing a layer starts with")

  START_SET("the timing an animation starts with")

  CABasicAnimation *a = [CABasicAnimation animation];

  PASS([a beginTime] == 0.0, "an animation begins at 0");
  PASS([a timeOffset] == 0.0, "an animation has no time offset");
  PASS([a repeatDuration] == 0.0, "an animation has no repeat duration");
  PASS([a autoreverses] == NO, "an animation does not autoreverse");
  PASS([a duration] == 0.0, "an animation's duration is 0");
  PASS([a speed] == 1.0, "an animation runs at speed 1");

  testHopeful = YES;
  PASS([a repeatCount] == 0.0, "an animation has a repeat count of 0");
  PASS([[a fillMode] isEqualToString: kCAFillModeRemoved],
       "an animation's fill mode is removed");
  testHopeful = NO;

  END_SET("the timing an animation starts with")

  START_SET("what the timing setters keep")

  CALayer *l = [CALayer layer];

  [l setBeginTime: 1.5];
  PASS([l beginTime] == 1.5, "the begin time reads back as it was set");

  [l setTimeOffset: 0.25];
  PASS([l timeOffset] == 0.25, "the time offset reads back as it was set");

  [l setRepeatCount: 3.0];
  PASS([l repeatCount] == 3.0, "the repeat count reads back as it was set");

  [l setRepeatDuration: 9.0];
  PASS([l repeatDuration] == 9.0,
       "the repeat duration reads back as it was set");

  [l setAutoreverses: YES];
  PASS([l autoreverses] == YES, "autoreverses reads back as it was set");

  [l setFillMode: kCAFillModeBoth];
  PASS([[l fillMode] isEqualToString: kCAFillModeBoth],
       "the fill mode reads back as it was set");

  [l setDuration: 2.0];
  PASS([l duration] == 2.0, "the duration reads back as it was set");

  [l setSpeed: 0.5];
  PASS([l speed] == 0.5, "the speed reads back as it was set");

  [l setRepeatCount: HUGE_VALF];
  PASS(isinf([l repeatCount]), "the repeat count can be made infinite");

  END_SET("what the timing setters keep")

  START_SET("the timing values a class hands out")

  PASS([[CALayer defaultValueForKey: @"speed"] floatValue] == 1.0,
       "a layer's speed comes from the class");
  PASS(isinf([[CALayer defaultValueForKey: @"duration"] doubleValue]),
       "a layer's duration comes from the class");

  testHopeful = YES;
  PASS([[CALayer defaultValueForKey: @"fillMode"]
         isEqualToString: kCAFillModeRemoved],
       "a layer's fill mode comes from the class");
  testHopeful = NO;

  END_SET("the timing values a class hands out")

  /* root -> mid -> leaf, so that the root can be told from the layer
     immediately above the one being asked. */
  START_SET("converting a time between layers")

  CALayer *root = [CALayer layer];
  CALayer *mid = [CALayer layer];
  CALayer *leaf = [CALayer layer];

  [root addSublayer: mid];
  [mid addSublayer: leaf];

  [mid setBeginTime: 2.0];
  [mid setSpeed: 3.0];
  [mid setTimeOffset: 0.25];

  [leaf setBeginTime: 1.0];
  [leaf setSpeed: 2.0];
  [leaf setTimeOffset: 0.5];

  PASS([leaf convertTime: 10.0 fromLayer: mid] == 18.5,
       "a time from the layer above is 18.5 in the leaf");
  PASS([leaf convertTime: 10.0 fromLayer: root] == 47.0,
       "a time from the root is 47 in the leaf, having crossed both layers");
  PASS([leaf convertTime: 10.0 toLayer: mid] == 5.75,
       "a leaf time is 5.75 in the layer above");
  /* The speed is a float, so the divisions do not land on 23/6 exactly. */
  PASS(fabs([leaf convertTime: 10.0 toLayer: root] - 23.0/6.0) < 1e-5,
       "a leaf time is 23/6 at the root");

  PASS(fabs([leaf convertTime: 10.0 toLayer: nil] - 23.0/6.0) < 1e-5,
       "converting to no layer reads the same as to the root");

  testHopeful = YES;
  PASS([leaf convertTime: 10.0 fromLayer: nil] == 47.0,
       "converting from no layer reads the same as from the root");
  testHopeful = NO;

  END_SET("converting a time between layers")

  [pool release];
  return 0;
}
