/* The value of each Core Animation string constant.
   Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/QuartzCore.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("Core Animation string constants")

  testHopeful = YES;

  PASS([kCAAnimationDiscrete isEqualToString: @"discrete"],
       "kCAAnimationDiscrete is \"discrete\"");
  PASS([kCAFillModeBackwards isEqualToString: @"backwards"],
       "kCAFillModeBackwards is \"backwards\"");
  PASS([kCAFillModeBoth isEqualToString: @"both"],
       "kCAFillModeBoth is \"both\"");
  PASS([kCAFillModeForwards isEqualToString: @"forwards"],
       "kCAFillModeForwards is \"forwards\"");
  PASS([kCAFillModeRemoved isEqualToString: @"removed"],
       "kCAFillModeRemoved is \"removed\"");
  PASS([kCAFillRuleEvenOdd isEqualToString: @"even-odd"],
       "kCAFillRuleEvenOdd is \"even-odd\"");
  PASS([kCAFillRuleNonZero isEqualToString: @"non-zero"],
       "kCAFillRuleNonZero is \"non-zero\"");
  PASS([kCAGravityBottom isEqualToString: @"bottom"],
       "kCAGravityBottom is \"bottom\"");
  PASS([kCAGravityBottomLeft isEqualToString: @"bottomLeft"],
       "kCAGravityBottomLeft is \"bottomLeft\"");
  PASS([kCAGravityBottomRight isEqualToString: @"bottomRight"],
       "kCAGravityBottomRight is \"bottomRight\"");
  PASS([kCAGravityCenter isEqualToString: @"center"],
       "kCAGravityCenter is \"center\"");
  PASS([kCAGravityLeft isEqualToString: @"left"],
       "kCAGravityLeft is \"left\"");
  PASS([kCAGravityResize isEqualToString: @"resize"],
       "kCAGravityResize is \"resize\"");
  PASS([kCAGravityResizeAspect isEqualToString: @"resizeAspect"],
       "kCAGravityResizeAspect is \"resizeAspect\"");
  PASS([kCAGravityResizeAspectFill isEqualToString: @"resizeAspectFill"],
       "kCAGravityResizeAspectFill is \"resizeAspectFill\"");
  PASS([kCAGravityRight isEqualToString: @"right"],
       "kCAGravityRight is \"right\"");
  PASS([kCAGravityTop isEqualToString: @"top"],
       "kCAGravityTop is \"top\"");
  PASS([kCAGravityTopLeft isEqualToString: @"topLeft"],
       "kCAGravityTopLeft is \"topLeft\"");
  PASS([kCAGravityTopRight isEqualToString: @"topRight"],
       "kCAGravityTopRight is \"topRight\"");
  PASS([kCALineCapButt isEqualToString: @"butt"],
       "kCALineCapButt is \"butt\"");
  PASS([kCALineCapRound isEqualToString: @"round"],
       "kCALineCapRound is \"round\"");
  PASS([kCALineCapSquare isEqualToString: @"square"],
       "kCALineCapSquare is \"square\"");
  PASS([kCALineJoinBevel isEqualToString: @"bevel"],
       "kCALineJoinBevel is \"bevel\"");
  PASS([kCALineJoinMiter isEqualToString: @"miter"],
       "kCALineJoinMiter is \"miter\"");
  PASS([kCALineJoinRound isEqualToString: @"round"],
       "kCALineJoinRound is \"round\"");
  PASS([kCAMediaTimingFunctionDefault isEqualToString: @"default"],
       "kCAMediaTimingFunctionDefault is \"default\"");
  PASS([kCAMediaTimingFunctionEaseIn isEqualToString: @"easeIn"],
       "kCAMediaTimingFunctionEaseIn is \"easeIn\"");
  PASS([kCAMediaTimingFunctionEaseInEaseOut isEqualToString: @"easeInEaseOut"],
       "kCAMediaTimingFunctionEaseInEaseOut is \"easeInEaseOut\"");
  PASS([kCAMediaTimingFunctionEaseOut isEqualToString: @"easeOut"],
       "kCAMediaTimingFunctionEaseOut is \"easeOut\"");
  PASS([kCAMediaTimingFunctionLinear isEqualToString: @"linear"],
       "kCAMediaTimingFunctionLinear is \"linear\"");
  PASS([kCAValueFunctionRotateX isEqualToString: @"rotateX"],
       "kCAValueFunctionRotateX is \"rotateX\"");
  PASS([kCAValueFunctionRotateY isEqualToString: @"rotateY"],
       "kCAValueFunctionRotateY is \"rotateY\"");
  PASS([kCAValueFunctionRotateZ isEqualToString: @"rotateZ"],
       "kCAValueFunctionRotateZ is \"rotateZ\"");
  PASS([kCAValueFunctionScale isEqualToString: @"scale"],
       "kCAValueFunctionScale is \"scale\"");
  PASS([kCAValueFunctionScaleX isEqualToString: @"scaleX"],
       "kCAValueFunctionScaleX is \"scaleX\"");
  PASS([kCAValueFunctionScaleY isEqualToString: @"scaleY"],
       "kCAValueFunctionScaleY is \"scaleY\"");
  PASS([kCAValueFunctionScaleZ isEqualToString: @"scaleZ"],
       "kCAValueFunctionScaleZ is \"scaleZ\"");
  PASS([kCAValueFunctionTranslate isEqualToString: @"translate"],
       "kCAValueFunctionTranslate is \"translate\"");
  PASS([kCAValueFunctionTranslateX isEqualToString: @"translateX"],
       "kCAValueFunctionTranslateX is \"translateX\"");
  PASS([kCAValueFunctionTranslateY isEqualToString: @"translateY"],
       "kCAValueFunctionTranslateY is \"translateY\"");
  PASS([kCAValueFunctionTranslateZ isEqualToString: @"translateZ"],
       "kCAValueFunctionTranslateZ is \"translateZ\"");

  testHopeful = NO;

  PASS([kCATransition isEqualToString: @"transition"],
       "kCATransition is \"transition\"");
  PASS([kCATransitionMoveIn isEqualToString: @"moveIn"],
       "kCATransitionMoveIn is \"moveIn\"");
  PASS([kCATransitionFromTop isEqualToString: @"fromTop"],
       "kCATransitionFromTop is \"fromTop\"");
  PASS([kCATransitionFromBottom isEqualToString: @"fromBottom"],
       "kCATransitionFromBottom is \"fromBottom\"");
  PASS([kCATransitionFromLeft isEqualToString: @"fromLeft"],
       "kCATransitionFromLeft is \"fromLeft\"");
  PASS([kCATransitionFromRight isEqualToString: @"fromRight"],
       "kCATransitionFromRight is \"fromRight\"");

  PASS([kCAAnimationLinear isEqualToString: @"linear"],
       "kCAAnimationLinear is \"linear\"");
  PASS([kCAAnimationPaced isEqualToString: @"paced"],
       "kCAAnimationPaced is \"paced\"");
  PASS([kCAAnimationCubic isEqualToString: @"cubic"],
       "kCAAnimationCubic is \"cubic\"");
  PASS([kCAAnimationCubicPaced isEqualToString: @"cubicPaced"],
       "kCAAnimationCubicPaced is \"cubicPaced\"");
  PASS([kCATransitionFade isEqualToString: @"fade"],
       "kCATransitionFade is \"fade\"");
  PASS([kCATransitionPush isEqualToString: @"push"],
       "kCATransitionPush is \"push\"");
  PASS([kCATransitionReveal isEqualToString: @"reveal"],
       "kCATransitionReveal is \"reveal\"");
  PASS([kCAOnOrderIn isEqualToString: @"onOrderIn"],
       "kCAOnOrderIn is \"onOrderIn\"");
  PASS([kCAOnOrderOut isEqualToString: @"onOrderOut"],
       "kCAOnOrderOut is \"onOrderOut\"");

  END_SET("Core Animation string constants")

  [pool release];
  return 0;
}
