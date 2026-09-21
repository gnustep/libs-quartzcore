/* What a CAAnimationGroup holds, and what a copy of one holds.

   Running the grouped animations is checked in apply.m, against API this
   framework declares privately.  Everything here is public API and holds
   against Apple QuartzCore as well. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CAAnimation.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("a group is an animation")

  CAAnimationGroup *g = [CAAnimationGroup animation];

  PASS(g != nil, "a group is made by +animation");
  PASS([CAAnimationGroup superclass] == [CAAnimation class],
       "a group derives from CAAnimation");
  PASS([g animations] == nil, "it holds no animations to begin with");

  END_SET("a group is an animation")

  START_SET("the animations a group holds")

  CAAnimationGroup *g = [CAAnimationGroup animation];
  CABasicAnimation *a = [CABasicAnimation animationWithKeyPath: @"opacity"];
  CABasicAnimation *b = [CABasicAnimation animationWithKeyPath: @"position"];
  NSMutableArray *both = [NSMutableArray arrayWithObjects: a, b, nil];

  [g setAnimations: both];

  PASS([[g animations] count] == 2, "a group holds the animations it is given");
  PASS([[g animations] objectAtIndex: 0] == a &&
       [[g animations] objectAtIndex: 1] == b,
       "in the order they were given in");

  [both removeAllObjects];

  PASS([[g animations] count] == 2,
       "the array is copied, so emptying the original leaves the group alone");

  [g setAnimations: nil];

  PASS([g animations] == nil, "and the group can be emptied again");

  END_SET("the animations a group holds")

  START_SET("copying a group")

  CAAnimationGroup *g = [CAAnimationGroup animation];
  CABasicAnimation *a = [CABasicAnimation animationWithKeyPath: @"opacity"];

  [g setAnimations: [NSArray arrayWithObject: a]];
  [g setDuration: 3.0];

  CAAnimationGroup *theCopy = [[g copy] autorelease];

  PASS([[theCopy animations] count] == 1,
       "a copy of a group carries the grouped animations");
  PASS([[theCopy animations] objectAtIndex: 0] == a,
       "the animations themselves, not copies of them");
  PASS([theCopy duration] == 3.0, "along with the timing of the group");

  END_SET("copying a group")

  [pool release];
  return 0;
}
