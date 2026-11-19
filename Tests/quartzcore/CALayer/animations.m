/* Removing the animations a layer holds.

   The expected values are the ones Apple QuartzCore produces. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/QuartzCore.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("removing every animation at once")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *one = [CABasicAnimation animationWithKeyPath: @"opacity"];
  CABasicAnimation *two = [CABasicAnimation animationWithKeyPath: @"position"];

  [layer addAnimation: one forKey: @"first"];
  [layer addAnimation: two forKey: @"second"];
  PASS([[layer animationKeys] count] == 2, "both animations are on the layer");

  [layer removeAllAnimations];
  PASS([[layer animationKeys] count] == 0, "removing them leaves none");
  PASS([layer animationForKey: @"first"] == nil,
       "and neither can be asked for by its key");
  PASS([layer animationForKey: @"second"] == nil, "either of them");

  END_SET("removing every animation at once")

  START_SET("removing when there is nothing to remove")

  CALayer *layer = [CALayer layer];

  PASS_RUNS([layer removeAllAnimations],
            "a layer with no animations does not raise");
  PASS([[layer animationKeys] count] == 0, "and still has none");

  END_SET("removing when there is nothing to remove")

  START_SET("removing twice")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *one = [CABasicAnimation animationWithKeyPath: @"opacity"];

  [layer addAnimation: one forKey: @"first"];
  [layer removeAllAnimations];
  PASS_RUNS([layer removeAllAnimations], "removing them again does not raise");
  PASS([[layer animationKeys] count] == 0, "and they are still gone");

  END_SET("removing twice")

  START_SET("what removing them does to the layer")

  CALayer *layer = [CALayer layer];
  CABasicAnimation *one = [CABasicAnimation animationWithKeyPath: @"opacity"];

  [layer addAnimation: one forKey: @"first"];
  [layer displayIfNeeded];
  [layer removeAllAnimations];
  PASS([layer needsDisplay] == NO,
       "taking the animations away does not redisplay the layer");

  END_SET("what removing them does to the layer")

  [pool release];
  return 0;
}
