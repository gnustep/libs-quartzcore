/* Running the animations a CAAnimationGroup holds.

   -applyToLayer: and the time authority an animation is evaluated in are
   GNUstep API with no counterpart in Apple QuartzCore, so this file is named
   in APPLE_SKIP_TESTS.  Apple documents the behaviour the values below
   check: the grouped animations keep their own durations and are clipped by
   the group rather than scaled into it. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <math.h>

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CAAnimation.h>

/* Declared by the framework, not by a public header. */
@interface CAAnimation (Apply)
- (void) applyToLayer: (CALayer *)layer;
- (void) applyToLayer: (CALayer *)layer
  withTimeAuthorityLocalTime: (CFTimeInterval)timeAuthorityLocalTime;
@end

@interface CALayer (Apply)
- (CFTimeInterval) applyAnimationsAtTime: (CFTimeInterval)theTime;
@end

#define CLOSE(a, b) (fabs((double)(a) - (double)(b)) < 1e-4)

static CABasicAnimation *
opacityFrom(float from, float to, CFTimeInterval duration)
{
  CABasicAnimation *b = [CABasicAnimation animationWithKeyPath: @"opacity"];

  [b setDuration: duration];
  [b setFromValue: [NSNumber numberWithFloat: from]];
  [b setToValue: [NSNumber numberWithFloat: to]];
  return b;
}

static CAAnimationGroup *
groupOf(CAAnimation *animation, CFTimeInterval duration)
{
  CAAnimationGroup *g = [CAAnimationGroup animation];

  [g setDuration: duration];
  [g setAnimations: [NSArray arrayWithObject: animation]];
  return g;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("a group runs the animations it holds")

  CALayer *layer = [CALayer layer];
  [layer setOpacity: 0.5];

  CAAnimationGroup *g = groupOf(opacityFrom(0.0, 1.0, 4.0), 4.0);
  [g applyToLayer: layer withTimeAuthorityLocalTime: 1.0];

  PASS(CLOSE([layer opacity], 0.25),
       "a quarter of the way through, the layer holds a quarter of the value");

  [g applyToLayer: layer withTimeAuthorityLocalTime: 3.0];

  PASS(CLOSE([layer opacity], 0.75), "and three quarters of the way through");

  END_SET("a group runs the animations it holds")

  START_SET("a group that holds nothing")

  CALayer *layer = [CALayer layer];
  [layer setOpacity: 0.5];

  CAAnimationGroup *g = [CAAnimationGroup animation];
  [g setDuration: 4.0];
  [g applyToLayer: layer withTimeAuthorityLocalTime: 1.0];

  PASS(CLOSE([layer opacity], 0.5), "leaves the layer where it was");

  END_SET("a group that holds nothing")

  START_SET("an animation longer than its group")

  /* Apple: the durations of the grouped animations are not scaled to the
     duration of the group, they are clipped to it.  An eight second
     animation in a two second group shows its first two seconds. */
  CALayer *layer = [CALayer layer];
  CAAnimationGroup *g = groupOf(opacityFrom(0.0, 1.0, 8.0), 2.0);

  [g applyToLayer: layer withTimeAuthorityLocalTime: 1.0];

  PASS(CLOSE([layer opacity], 0.125),
       "one second in, the animation is one eighth of its own duration along");

  END_SET("an animation longer than its group")

  START_SET("an animation shorter than its group")

  CALayer *layer = [CALayer layer];
  CAAnimationGroup *g = groupOf(opacityFrom(0.0, 1.0, 2.0), 8.0);

  [g applyToLayer: layer withTimeAuthorityLocalTime: 1.0];

  PASS(CLOSE([layer opacity], 0.5),
       "one second in, it is half way through its own two seconds");

  END_SET("an animation shorter than its group")

  START_SET("the time a grouped animation begins")

  /* The animations are evaluated in the time space of the group, so a begin
     time inside one is counted from the start of the group. */
  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = opacityFrom(0.0, 1.0, 2.0);
  [b setBeginTime: 1.0];

  CAAnimationGroup *g = groupOf(b, 4.0);
  [g applyToLayer: layer withTimeAuthorityLocalTime: 2.0];

  PASS(CLOSE([layer opacity], 0.5),
       "a second after it begins it is half way through its two seconds");

  END_SET("the time a grouped animation begins")

  START_SET("the time the group itself begins")

  CALayer *layer = [CALayer layer];
  CAAnimationGroup *g = groupOf(opacityFrom(0.0, 1.0, 4.0), 4.0);
  [g setBeginTime: 2.0];

  [g applyToLayer: layer withTimeAuthorityLocalTime: 3.0];

  PASS(CLOSE([layer opacity], 0.25),
       "the group starts its animations when the group itself begins");

  END_SET("the time the group itself begins")

  START_SET("a group inside a group")

  CALayer *layer = [CALayer layer];
  CAAnimationGroup *inner = groupOf(opacityFrom(0.0, 1.0, 4.0), 4.0);
  CAAnimationGroup *outer = groupOf(inner, 4.0);

  [outer applyToLayer: layer withTimeAuthorityLocalTime: 1.0];

  PASS(CLOSE([layer opacity], 0.25),
       "the innermost animation is reached through both groups");

  END_SET("a group inside a group")

  START_SET("applying a group with no time of its own")

  CALayer *layer = [CALayer layer];
  [layer setOpacity: 0.5];

  CAAnimationGroup *g = groupOf(opacityFrom(0.0, 1.0, 4.0), 4.0);
  [g applyToLayer: layer];

  PASS(CLOSE([layer opacity], 0.0),
       "a layer that is nothing's presentation layer gives the time zero");

  END_SET("applying a group with no time of its own")

  START_SET("a layer runs a group it was given")

  CALayer *layer = [CALayer layer];
  [layer setOpacity: 0.25];

  CAAnimationGroup *g = groupOf(opacityFrom(0.0, 1.0, 4.0), 4.0);
  [g setBeginTime: CACurrentMediaTime()];
  [layer addAnimation: g forKey: @"group"];

  CALayer *presentation = [layer presentationLayer];
  [presentation applyAnimationsAtTime: CACurrentMediaTime()];

  PASS([presentation opacity] < 0.01,
       "a group that has just begun writes the value its animations start at");
  PASS(CLOSE([layer opacity], 0.25),
       "and the model layer keeps the value it had");

  END_SET("a layer runs a group it was given")

  [pool release];
  return 0;
}
