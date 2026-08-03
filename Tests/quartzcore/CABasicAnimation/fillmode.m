/* What an animation shows outside its own duration.

   Apple describes the four: removed, which an animation starts with, shows
   nothing at either end; forwards holds the value the animation ends at
   after it has ended; backwards holds the one it starts from before it
   begins; and both does the two.

   -applyToLayer: is GNUstep API with no counterpart in Apple QuartzCore, so
   this file is named in APPLE_SKIP_TESTS. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <math.h>

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAMediaTiming.h>
#import <QuartzCore/CATransaction.h>

/* Declared by the framework, not by a public header. */
@interface CAPropertyAnimation (Interpolation)
- (void) applyToLayer: (CALayer *)layer;
@end

#define CLOSE(a, b) (fabs((double)(a) - (double)(b)) < 1e-4)

/* A layer whose opacity is a half, and an animation from nothing to whole
   that either has not begun yet or is long over.  Applying it to the layer
   is what the fill mode governs. */
static float
opacityAfterApplying(NSString *fillMode, BOOL over)
{
  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = [CABasicAnimation animationWithKeyPath: @"opacity"];

  [CATransaction begin];
  [CATransaction setDisableActions: YES];

  [layer setOpacity: 0.5];

  [b setDuration: 1.0];
  [b setFromValue: [NSNumber numberWithFloat: 0.0]];
  [b setToValue: [NSNumber numberWithFloat: 1.0]];
  [b setFillMode: fillMode];
  [b setBeginTime: CACurrentMediaTime() + (over ? -100.0 : 100.0)];

  [b applyToLayer: layer];

  [CATransaction commit];

  return [layer opacity];
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the fill mode an animation starts with")

  CABasicAnimation *b = [CABasicAnimation animation];

  PASS([[b fillMode] isEqualToString: kCAFillModeRemoved]
       || [b fillMode] == nil,
       "an animation starts with nothing filled in at either end");

  PASS(CLOSE(opacityAfterApplying([b fillMode], NO), 0.5),
       "so before it begins the layer keeps its own value");
  PASS(CLOSE(opacityAfterApplying([b fillMode], YES), 0.5),
       "and after it ends the layer keeps its own value");

  END_SET("the fill mode an animation starts with")

  START_SET("filling forwards")

  PASS(CLOSE(opacityAfterApplying(kCAFillModeForwards, YES), 1.0),
       "after it ends the value it ended at is held");
  PASS(CLOSE(opacityAfterApplying(kCAFillModeForwards, NO), 0.5),
       "and before it begins the layer is still left alone");

  END_SET("filling forwards")

  START_SET("filling backwards")

  PASS(CLOSE(opacityAfterApplying(kCAFillModeBackwards, NO), 0.0),
       "before it begins the value it starts from is held");
  PASS(CLOSE(opacityAfterApplying(kCAFillModeBackwards, YES), 0.5),
       "and after it ends the layer is left alone");

  END_SET("filling backwards")

  START_SET("filling both ends")

  PASS(CLOSE(opacityAfterApplying(kCAFillModeBoth, NO), 0.0),
       "both holds the value at the near end");
  PASS(CLOSE(opacityAfterApplying(kCAFillModeBoth, YES), 1.0),
       "and at the far one");

  END_SET("filling both ends")

  START_SET("a fill mode that means nothing")

  PASS(CLOSE(opacityAfterApplying(@"aFillModeNobodyDefines", YES), 0.5),
       "a fill mode the framework does not know fills neither end");

  END_SET("a fill mode that means nothing")

  START_SET("within the duration")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *b = [CABasicAnimation animationWithKeyPath: @"opacity"];

  [CATransaction begin];
  [CATransaction setDisableActions: YES];

  [layer setOpacity: 0.5];
  [b setDuration: 100.0];
  [b setFromValue: [NSNumber numberWithFloat: 0.0]];
  [b setToValue: [NSNumber numberWithFloat: 1.0]];
  [b setBeginTime: CACurrentMediaTime() - 50.0];
  [b applyToLayer: layer];

  [CATransaction commit];

  PASS([layer opacity] > 0.4 && [layer opacity] < 0.6,
       "an animation part way through is applied whatever its fill mode");

  END_SET("within the duration")

  [pool release];
  return 0;
}
