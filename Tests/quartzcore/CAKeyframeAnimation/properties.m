/* What a keyframe animation holds.  These are Apple's properties and the
   values below were measured against it. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/QuartzCore.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what it starts with")

  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"opacity"];

  PASS([CAKeyframeAnimation superclass] == [CAPropertyAnimation class],
       "a keyframe animation is a property animation");
  PASS([[k calculationMode] isEqualToString: kCAAnimationLinear],
       "it interpolates between its values unless told otherwise");
  PASS([k values] == nil, "with no values");
  PASS([k keyTimes] == nil, "no key times");
  PASS([k timingFunctions] == nil, "and no timing functions");

  END_SET("what it starts with")

  START_SET("the calculation modes")

  PASS([kCAAnimationLinear isEqualToString: @"linear"], "linear");
  PASS([kCAAnimationDiscrete isEqualToString: @"discrete"], "discrete");
  PASS([kCAAnimationPaced isEqualToString: @"paced"], "paced");
  PASS([kCAAnimationCubic isEqualToString: @"cubic"], "cubic");
  PASS([kCAAnimationCubicPaced isEqualToString: @"cubicPaced"], "cubic paced");

  END_SET("the calculation modes")

  START_SET("what it answers for")

  PASS([[CAKeyframeAnimation defaultValueForKey: @"calculationMode"]
         isEqualToString: kCAAnimationLinear],
       "the class names the mode it starts in");
  PASS([CAKeyframeAnimation defaultValueForKey: @"values"] == nil,
       "and names no values");

  END_SET("what it answers for")

  START_SET("the arrays are copied")

  CAKeyframeAnimation *k =
    [CAKeyframeAnimation animationWithKeyPath: @"opacity"];
  NSMutableArray *given = [NSMutableArray arrayWithObjects:
    [NSNumber numberWithFloat: 0.0], [NSNumber numberWithFloat: 1.0], nil];

  [k setValues: given];
  [given removeAllObjects];

  PASS([[k values] count] == 2,
       "emptying the array afterwards leaves the animation alone");

  [k setCalculationMode: @"nonsense"];

  PASS([[k calculationMode] isEqualToString: @"nonsense"],
       "a mode it does not know is kept as it was given");

  END_SET("the arrays are copied")

  [pool release];
  return 0;
}
