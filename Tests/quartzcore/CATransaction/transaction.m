/* The transaction stack, the values a transaction carries, and key-value
   access to them.  Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CATransaction.h>
#import <QuartzCore/CAMediaTimingFunction.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("CATransaction key names")

  PASS([kCATransactionAnimationDuration
         isEqualToString: @"animationDuration"],
       "kCATransactionAnimationDuration is \"animationDuration\"");
  PASS([kCATransactionDisableActions isEqualToString: @"disableActions"],
       "kCATransactionDisableActions is \"disableActions\"");
  PASS([kCATransactionAnimationTimingFunction
         isEqualToString: @"animationTimingFunction"],
       "kCATransactionAnimationTimingFunction is"
       " \"animationTimingFunction\"");

  END_SET("CATransaction key names")

  /* Read the implicit transaction before anything has modified it. */
  START_SET("values with no transaction started")

  PASS([CATransaction animationDuration] == 0.25,
       "the animation duration is 0.25 when no transaction has been begun");
  PASS([CATransaction disableActions] == NO,
       "actions are enabled when no transaction has been begun");

  testHopeful = YES;
  PASS([CATransaction animationTimingFunction] == nil,
       "no timing function is set when no transaction has been begun");
  testHopeful = NO;

  END_SET("values with no transaction started")

  START_SET("setting values on a transaction")

  [CATransaction begin];

  PASS([CATransaction animationDuration] == 0.25,
       "a transaction begins with an animation duration of 0.25");

  [CATransaction setAnimationDuration: 1.5];
  PASS([CATransaction animationDuration] == 1.5,
       "the animation duration reads back as it was set");

  [CATransaction setDisableActions: YES];
  PASS([CATransaction disableActions] == YES,
       "disabling actions reads back as it was set");

  [CATransaction setAnimationTimingFunction:
    [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn]];
  PASS([CATransaction animationTimingFunction] != nil,
       "the timing function reads back after it is set");
  {
    float cp[2];

    [[CATransaction animationTimingFunction] getControlPointAtIndex: 1
                                                             values: cp];
    PASS(cp[0] == 0.42f && cp[1] == 0.0f,
         "the timing function that reads back is the one that was set");
  }

  [CATransaction commit];

  PASS([CATransaction animationDuration] == 0.25,
       "committing restores the animation duration of the enclosing"
       " transaction");
  PASS([CATransaction disableActions] == NO,
       "committing restores the actions setting of the enclosing"
       " transaction");

  testHopeful = YES;
  PASS([CATransaction animationTimingFunction] == nil,
       "committing restores the timing function of the enclosing"
       " transaction");
  testHopeful = NO;

  END_SET("setting values on a transaction")

  START_SET("nested transactions")

  [CATransaction begin];
  [CATransaction setAnimationDuration: 1.0];
  [CATransaction setDisableActions: YES];

  [CATransaction begin];

  testHopeful = YES;
  PASS([CATransaction animationDuration] == 1.0,
       "a nested transaction sees the animation duration of the enclosing"
       " one");
  PASS([CATransaction disableActions] == YES,
       "a nested transaction sees the actions setting of the enclosing one");
  testHopeful = NO;

  [CATransaction setAnimationDuration: 2.0];
  PASS([CATransaction animationDuration] == 2.0,
       "a nested transaction takes the duration it is given");

  [CATransaction commit];

  PASS([CATransaction animationDuration] == 1.0,
       "a nested transaction does not carry its duration out to the"
       " enclosing one");
  PASS([CATransaction disableActions] == YES,
       "the enclosing transaction keeps its actions setting");

  [CATransaction commit];

  END_SET("nested transactions")

  START_SET("reading and writing values by key")

  [CATransaction begin];

  [CATransaction setAnimationDuration: 0.75];
  PASS([[CATransaction valueForKey: kCATransactionAnimationDuration]
         doubleValue] == 0.75,
       "the duration key reads what the accessor set");

  [CATransaction setValue: [NSNumber numberWithDouble: 1.25]
                   forKey: kCATransactionAnimationDuration];
  PASS([CATransaction animationDuration] == 1.25,
       "the accessor reads what the duration key set");

  [CATransaction setDisableActions: YES];
  PASS([[CATransaction valueForKey: kCATransactionDisableActions]
         boolValue] == YES,
       "the actions key reads what the accessor set");

  [CATransaction setValue: [NSNumber numberWithBool: NO]
                   forKey: kCATransactionDisableActions];
  PASS([CATransaction disableActions] == NO,
       "the accessor reads what the actions key set");

  [CATransaction commit];

  END_SET("reading and writing values by key")

  /* A transaction on Apple carries arbitrary key-value pairs, and an unset
     key reads as nil rather than raising.  Both of these end the set early
     where they raise, so they come last. */
  START_SET("keys a transaction does not define")

  [CATransaction begin];

  testHopeful = YES;

  {
    id fetched = nil;

    PASS_RUNS(fetched = [CATransaction valueForKey: @"aKeyNobodyDefined"],
              "reading a key the transaction does not define does not raise");
    PASS_RUNS([CATransaction setValue: @"stored" forKey: @"aKeyNobodyDefined"],
              "an arbitrary key can be set on a transaction");
    PASS_RUNS(fetched = [CATransaction valueForKey: @"aKeyNobodyDefined"],
              "an arbitrary key can be read back from a transaction");
    PASS([fetched isEqual: @"stored"],
         "an arbitrary key round-trips through a transaction");
  }

  testHopeful = NO;

  [CATransaction commit];

  END_SET("keys a transaction does not define")

  START_SET("the class methods that take no transaction")

  PASS_RUNS([CATransaction commit],
            "committing with no matching begin does not raise");
  PASS([CATransaction animationDuration] == 0.25,
       "an unmatched commit leaves the animation duration at 0.25");

  PASS_RUNS([CATransaction flush], "flush does not raise");
  PASS_RUNS([CATransaction lock]; [CATransaction unlock],
            "lock and unlock do not raise");

  END_SET("the class methods that take no transaction")

  [pool release];
  return 0;
}
