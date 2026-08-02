/* Implicit animation: a property change inside a transaction animates, and
   disabling actions for that transaction stops it.

   Apple documents setDisableActions: as suppressing the actions triggered by
   property changes made within the transaction group.  A standalone layer
   answers nil from -animationKeys throughout on Apple, so what is checked
   here cannot be checked against it, and this file is not run there. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CATransaction.h>

static BOOL
animatesPosition(CALayer *layer)
{
  return [layer animationForKey: @"position"] != nil;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("a property change inside a transaction")

  CALayer *l = [CALayer layer];

  PASS(!animatesPosition(l), "a fresh layer is not animating");

  [CATransaction begin];
  [l setPosition: CGPointMake(20, 20)];
  [CATransaction commit];

  PASS(animatesPosition(l), "changing the position animates it");
  PASS([l position].x == 20, "the position is the one it was set to");

  END_SET("a property change inside a transaction")

  START_SET("a transaction with its actions disabled")

  CALayer *l = [CALayer layer];

  [CATransaction begin];
  [CATransaction setDisableActions: YES];
  PASS([CATransaction disableActions], "the transaction says actions are off");
  [l setPosition: CGPointMake(30, 30)];
  [CATransaction commit];

  PASS(!animatesPosition(l), "with actions off the change does not animate");
  PASS([l position].x == 30, "with actions off the position still changes");

  END_SET("a transaction with its actions disabled")

  START_SET("actions are disabled for one transaction only")

  CALayer *l = [CALayer layer];

  [CATransaction begin];
  [CATransaction setDisableActions: YES];
  [l setPosition: CGPointMake(40, 40)];
  [CATransaction commit];

  PASS(!animatesPosition(l), "the first change does not animate");

  [CATransaction begin];
  [l setPosition: CGPointMake(50, 50)];
  [CATransaction commit];

  PASS(animatesPosition(l), "a later transaction animates again");

  END_SET("actions are disabled for one transaction only")

  START_SET("setting a property to the value it already has")

  CALayer *l = [CALayer layer];

  [CATransaction begin];
  [l setPosition: CGPointMake(60, 60)];
  [CATransaction commit];
  [l removeAnimationForKey: @"position"];

  [CATransaction begin];
  [l setPosition: CGPointMake(60, 60)];
  [CATransaction commit];

  PASS(!animatesPosition(l), "setting the same value again does not animate");

  END_SET("setting a property to the value it already has")

  [pool release];
  return 0;
}
