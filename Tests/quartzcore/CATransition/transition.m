/* The values a transition starts with, and what its setters keep.
   Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CAAnimation.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the values a transition starts with")

  CATransition *t = [CATransition animation];

  PASS(t != nil, "a transition can be created");
  PASS([t isKindOfClass: [CAAnimation class]], "a transition is an animation");
  PASS([t subtype] == nil, "it starts with no subtype");
  PASS([t duration] == 0.0, "it starts with a duration of 0");

  /* Apple names this "fade"; the constant for it arrives with #26. */
  testHopeful = YES;
  PASS([[t type] isEqualToString: @"fade"], "it starts as a fade");
  testHopeful = NO;

  END_SET("the values a transition starts with")

  START_SET("what a transition's setters keep")

  CATransition *t = [CATransition animation];

  /* Spelled out rather than named, because kCATransitionMoveIn and the
     subtype constants beside it are declared but defined nowhere until #25. */
  [t setType: @"moveIn"];
  PASS([[t type] isEqualToString: @"moveIn"],
       "the type reads back as it was set");

  [t setSubtype: @"fromLeft"];
  PASS([[t subtype] isEqualToString: @"fromLeft"],
       "the subtype reads back as it was set");

  END_SET("what a transition's setters keep")

  [pool release];
  return 0;
}
