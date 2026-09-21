/* The transaction stack, the values a transaction carries, and key-value
   access to them.  Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CATransaction.h>
#import <QuartzCore/CAMediaTimingFunction.h>

/* What another thread makes of a transaction this one holds open.  The
   answer does not depend on how the two are scheduled, so nothing here is
   timing dependent; the condition only waits for the other thread to finish,
   and it has a deadline so a mistake cannot hang the run. */
static NSCondition *gate = nil;
static BOOL         otherFinished = NO;
static double       otherDuration = -1.0;
static BOOL         otherDisableActions = YES;

@interface QCOtherThread : NSObject
+ (void) look: (id)ignored;
+ (void) runItsOwn: (id)ignored;
@end

@implementation QCOtherThread

+ (void) look: (id)ignored
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  otherDuration = (double)[CATransaction animationDuration];
  otherDisableActions = [CATransaction disableActions];
  [pool release];

  [gate lock];
  otherFinished = YES;
  [gate signal];
  [gate unlock];
}

+ (void) runItsOwn: (id)ignored
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  [CATransaction begin];
  [CATransaction setAnimationDuration: 11.0];
  otherDuration = (double)[CATransaction animationDuration];
  [CATransaction commit];
  [pool release];

  [gate lock];
  otherFinished = YES;
  [gate signal];
  [gate unlock];
}

@end

static BOOL runOnAnotherThread(SEL what)
{
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow: 10.0];
  BOOL ok = YES;

  otherFinished = NO;
  otherDuration = -1.0;
  otherDisableActions = YES;
  [NSThread detachNewThreadSelector: what
                           toTarget: [QCOtherThread class]
                         withObject: nil];

  [gate lock];
  while (!otherFinished)
    {
      if (![gate waitUntilDate: deadline])
        {
          ok = NO;
          break;
        }
    }
  [gate unlock];

  return ok;
}

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

  START_SET("flushing")

  [CATransaction setAnimationDuration: 5.0];
  PASS([CATransaction animationDuration] == 5.0,
       "the implicit transaction takes a duration like any other");

  [CATransaction flush];
  PASS([CATransaction animationDuration] == 0.25,
       "flushing takes the implicit transaction away");

  [CATransaction begin];
  [CATransaction setAnimationDuration: 7.0];
  [CATransaction flush];
  PASS([CATransaction animationDuration] == 7.0,
       "a flush leaves an explicit transaction where it is");
  [CATransaction commit];

  PASS([CATransaction animationDuration] == 0.25,
       "and once that is committed there is nothing left of it");

  PASS_RUNS([CATransaction flush]; [CATransaction flush],
            "flushing when there is nothing to flush does nothing");

  END_SET("flushing")

  START_SET("the lock")

  PASS_RUNS([CATransaction lock]; [CATransaction unlock],
            "a lock can be taken and given back");

  PASS_RUNS([CATransaction lock]; [CATransaction lock];
            [CATransaction unlock]; [CATransaction unlock],
            "and taken twice over by the one thread");

  [CATransaction lock];
  [CATransaction begin];
  [CATransaction setAnimationDuration: 9.0];
  PASS([CATransaction animationDuration] == 9.0,
       "a transaction still works while the lock is held");
  [CATransaction commit];
  [CATransaction unlock];

  PASS_RUNS([CATransaction unlock],
            "giving back a lock that was never taken does nothing");

  END_SET("the lock")

  START_SET("a transaction belongs to the thread that began it")

  gate = [NSCondition new];

  [CATransaction begin];
  [CATransaction setAnimationDuration: 5.0];
  [CATransaction setDisableActions: YES];

  PASS(runOnAnotherThread(@selector(look:)),
       "another thread can read a transaction value at all");
  PASS(otherDuration == 0.25,
       "and reads its own duration rather than this thread's");
  PASS(otherDisableActions == NO,
       "and its own actions setting rather than this thread's");
  PASS([CATransaction animationDuration] == 5.0,
       "while this thread still reads what it set");

  [CATransaction commit];
  PASS([CATransaction animationDuration] == 0.25,
       "and commits its own transaction away");

  [CATransaction begin];
  [CATransaction setAnimationDuration: 3.0];

  PASS(runOnAnotherThread(@selector(runItsOwn:)),
       "another thread can run a transaction of its own");
  PASS(otherDuration == 11.0, "and sees the value it set in it");
  PASS([CATransaction animationDuration] == 3.0,
       "without disturbing the one open on this thread");

  [CATransaction commit];
  PASS([CATransaction animationDuration] == 0.25,
       "which still commits cleanly afterwards");

  END_SET("a transaction belongs to the thread that began it")

  [pool release];
  return 0;
}
