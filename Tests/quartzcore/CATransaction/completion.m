/* Being told once a transaction has been committed.
   Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CATransaction.h>

static void turn(void)
{
  [[NSRunLoop currentRunLoop] runUntilDate:
    [NSDate dateWithTimeIntervalSinceNow: 0.3]];
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

#if defined(__BLOCKS__)
  __block int ran = 0;

  START_SET("what the completion block reads as")

  [CATransaction begin];
  PASS([CATransaction completionBlock] == nil,
       "a transaction starts with nothing to be told");

  [CATransaction setCompletionBlock: ^{ ran++; }];
  PASS([CATransaction completionBlock] != nil,
       "and answers what it was given");

  [CATransaction commit];
  turn();
  PASS([CATransaction completionBlock] == nil,
       "which is gone once that transaction has been committed");

  END_SET("what the completion block reads as")

  START_SET("when it runs")

  ran = 0;
  [CATransaction begin];
  [CATransaction setCompletionBlock: ^{ ran++; }];
  [CATransaction commit];
  PASS(ran == 0, "committing does not run it there and then");

  turn();
  PASS(ran == 1, "a turn of the run loop does");

  turn();
  PASS(ran == 1, "and it runs the once");

  END_SET("when it runs")

  START_SET("a transaction left open")

  ran = 0;
  [CATransaction begin];
  [CATransaction setCompletionBlock: ^{ ran++; }];
  turn();
  PASS(ran == 0, "a transaction still open does not run it");

  [CATransaction commit];
  turn();
  PASS(ran == 1, "committing it does");

  END_SET("a transaction left open")

  START_SET("more than one")

  __block int first = 0;
  __block int second = 0;

  [CATransaction begin];
  [CATransaction setCompletionBlock: ^{ first++; }];
  [CATransaction setCompletionBlock: ^{ second++; }];
  [CATransaction commit];
  turn();
  PASS(first == 1 && second == 1,
       "setting a second adds to the first rather than replacing it");

  END_SET("more than one")

  START_SET("clearing one")

  ran = 0;
  [CATransaction begin];
  [CATransaction setCompletionBlock: ^{ ran++; }];
  [CATransaction setCompletionBlock: nil];
  PASS([CATransaction completionBlock] == nil,
       "clearing it leaves nothing to read");
  [CATransaction commit];
  turn();
  PASS(ran == 1, "but what was already asked for still runs");

  END_SET("clearing one")

  START_SET("a nested transaction")

  ran = 0;
  [CATransaction begin];
  [CATransaction setCompletionBlock: ^{ ran++; }];

  [CATransaction begin];
  PASS([CATransaction completionBlock] != nil,
       "a nested transaction reads the one it is nested in");
  [CATransaction commit];
  turn();
  PASS(ran == 0, "committing the nested one does not run it");

  [CATransaction commit];
  turn();
  PASS(ran == 1, "committing the one that was given it does");

  END_SET("a nested transaction")
#endif

  [pool release];
  return 0;
}
