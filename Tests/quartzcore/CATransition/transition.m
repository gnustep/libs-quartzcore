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

  PASS([[t type] isEqualToString: @"fade"], "it starts as a fade");
  PASS([[t type] isEqualToString: kCATransitionFade],
       "which is the string the constant for it names");

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

  START_SET("how much of the transition is run")

  CATransition *t = [CATransition animation];

  PASS([t startProgress] == 0.0, "it starts at the beginning");
  PASS([t endProgress] == 1.0, "and runs to the end");
  PASS([t filter] == nil, "with no filter of its own");

  [t setStartProgress: 0.25];
  [t setEndProgress: 0.75];
  PASS([t startProgress] == 0.25 && [t endProgress] == 0.75,
       "the stretch it is given is the stretch it keeps");

  END_SET("how much of the transition is run")

  START_SET("a stretch that makes no sense")

  CATransition *outside = [CATransition animation];
  CATransition *crossed = [CATransition animation];

  [outside setStartProgress: -1.0];
  [outside setEndProgress: 2.0];
  PASS([outside startProgress] == -1.0 && [outside endProgress] == 2.0,
       "a value outside nought to one is kept as it was given");

  /* Halves and quarters, so that what is read back is what was written
     rather than the nearest float to it. */
  [crossed setStartProgress: 0.75];
  [crossed setEndProgress: 0.25];
  PASS([crossed startProgress] == 0.75 && [crossed endProgress] == 0.25,
       "and so is a start that comes after its end");

  END_SET("a stretch that makes no sense")

  START_SET("the filter a transition is given")

  CATransition *t = [CATransition animation];
  id thing = [NSNumber numberWithInt: 7];

  [t setFilter: thing];
  PASS([t filter] == thing, "the filter reads back as the object it was given");

  [t setFilter: nil];
  PASS([t filter] == nil, "and can be taken away again");

  END_SET("the filter a transition is given")

  [pool release];
  return 0;
}
