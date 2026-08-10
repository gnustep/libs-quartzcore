/* Asking to be told about a commit without a block, so that a compiler
   without them can still be told.  Apple has no such method, so this file is
   not run against it. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CATransaction.h>

static int told = 0;
static int toldAgain = 0;

@interface QCTellMe : NSObject
+ (void) tell;
+ (void) tellAgain;
@end

@implementation QCTellMe
+ (void) tell { told++; }
+ (void) tellAgain { toldAgain++; }
@end

static void turn(void)
{
  [[NSRunLoop currentRunLoop] runUntilDate:
    [NSDate dateWithTimeIntervalSinceNow: 0.3]];
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("being told by target and selector")

  told = 0;
  [CATransaction begin];
  [CATransaction setCompletionTarget: [QCTellMe class]
                            selector: @selector(tell)];
  [CATransaction commit];
  PASS(told == 0, "committing does not tell it there and then");

  turn();
  PASS(told == 1, "a turn of the run loop does");

  turn();
  PASS(told == 1, "and it is told the once");

  END_SET("being told by target and selector")

  START_SET("more than one to tell")

  told = 0;
  toldAgain = 0;
  [CATransaction begin];
  [CATransaction setCompletionTarget: [QCTellMe class]
                            selector: @selector(tell)];
  [CATransaction setCompletionTarget: [QCTellMe class]
                            selector: @selector(tellAgain)];
  [CATransaction commit];
  turn();
  PASS(told == 1 && toldAgain == 1, "both are told");

  END_SET("more than one to tell")

  START_SET("nothing to tell")

  PASS_RUNS([CATransaction begin];
            [CATransaction setCompletionTarget: nil selector: NULL];
            [CATransaction commit],
            "being given nothing to tell does nothing");

  END_SET("nothing to tell")

  [pool release];
  return 0;
}
