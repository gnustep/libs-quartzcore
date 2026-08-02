/* The values each animation class starts with, what its setters keep, and
   copying one.  Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CAMediaTimingFunction.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the values an animation starts with")

  CAAnimation *a = [CAAnimation animation];

  PASS(a != nil, "an animation can be created");
  PASS([a delegate] == nil, "it starts with no delegate");
  PASS([a timingFunction] == nil, "it starts with no timing function");
  PASS([a removedOnCompletion] == YES,
       "it is removed when it completes");

  END_SET("the values an animation starts with")

  START_SET("the values a property animation starts with")

  CAPropertyAnimation *p = [CAPropertyAnimation animation];

  PASS([p keyPath] == nil, "it starts with no key path");
  PASS([p isAdditive] == NO, "it is not additive");
  PASS([p isCumulative] == NO, "it is not cumulative");
  PASS([p valueFunction] == nil, "it starts with no value function");

  CAPropertyAnimation *k =
    [CAPropertyAnimation animationWithKeyPath: @"opacity"];

  PASS([[k keyPath] isEqualToString: @"opacity"],
       "animationWithKeyPath: keeps the key path it is given");
  PASS([k isKindOfClass: [CAPropertyAnimation class]],
       "animationWithKeyPath: answers a property animation");

  END_SET("the values a property animation starts with")

  START_SET("the values a basic animation starts with")

  CABasicAnimation *b = [CABasicAnimation animation];

  PASS([b fromValue] == nil, "it starts with no from value");
  PASS([b toValue] == nil, "it starts with no to value");
  PASS([b byValue] == nil, "it starts with no by value");
  PASS([b keyPath] == nil, "it starts with no key path");

  END_SET("the values a basic animation starts with")

  START_SET("the values a keyframe animation starts with")

  CAKeyframeAnimation *k = [CAKeyframeAnimation animation];

  PASS([k values] == nil, "it starts with no values");

  /* Apple names this "linear"; the constant for it arrives with #26. */
  testHopeful = YES;
  PASS([[k calculationMode] isEqualToString: @"linear"],
       "it starts calculating linearly");
  testHopeful = NO;

  END_SET("the values a keyframe animation starts with")

  START_SET("the values a spring animation starts with")

  CASpringAnimation *s = [CASpringAnimation animation];

  testHopeful = YES;
  PASS([s mass] == 1.0, "a spring starts with a mass of 1");
  PASS([s stiffness] == 100.0, "a spring starts with a stiffness of 100");
  PASS([s damping] == 10.0, "a spring starts with a damping of 10");
  PASS([s settlingDuration] > 0.0,
       "a spring works out how long it takes to settle");
  testHopeful = NO;

  PASS([s initialVelocity] == 0.0, "a spring starts at rest");

  END_SET("the values a spring animation starts with")

  START_SET("what an animation's setters keep")

  CABasicAnimation *b = [CABasicAnimation animation];
  CAMediaTimingFunction *fn =
    [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn];

  [b setKeyPath: @"position"];
  PASS([[b keyPath] isEqualToString: @"position"],
       "the key path reads back as it was set");

  [b setToValue: [NSNumber numberWithInt: 7]];
  PASS([[b toValue] intValue] == 7, "the to value reads back as it was set");

  [b setFromValue: [NSNumber numberWithInt: 3]];
  PASS([[b fromValue] intValue] == 3,
       "the from value reads back as it was set");

  [b setTimingFunction: fn];
  PASS([b timingFunction] == fn,
       "the timing function reads back as it was set");

  [b setRemovedOnCompletion: NO];
  PASS([b removedOnCompletion] == NO,
       "removed on completion reads back as it was set");

  [b setAdditive: YES];
  PASS([b isAdditive] == YES, "additive reads back as it was set");

  [b setCumulative: YES];
  PASS([b isCumulative] == YES, "cumulative reads back as it was set");

  END_SET("what an animation's setters keep")

  /* -delegate is an atomic property getter, so it answers something
     autoreleased and reading it moves the count.  The two counted
     assertions below therefore never call it. */
  START_SET("an animation owns its delegate")

  NSObject *named = [[[NSObject alloc] init] autorelease];
  CAAnimation *reader = [CAAnimation animation];

  [reader setDelegate: named];
  PASS([reader delegate] == named, "the delegate reads back as it was set");

  NSObject *d = [[NSObject alloc] init];
  CAAnimation *a = [CAAnimation animation];
  NSUInteger before = [d retainCount];

  [a setDelegate: d];
  PASS([d retainCount] == before + 1,
       "an animation retains its delegate, unlike most delegates");

  [a setDelegate: nil];
  PASS([d retainCount] == before, "and lets go of it when it is replaced");
  [d release];

  END_SET("an animation owns its delegate")

  START_SET("copying an animation")

  CABasicAnimation *b = [CABasicAnimation animation];

  [b setKeyPath: @"position"];
  [b setDuration: 3.0];
  [b setToValue: [NSNumber numberWithInt: 7]];
  [b setRepeatCount: 2.0];

  CABasicAnimation *c = [b copy];

  PASS(c != b, "a copy is a distinct object");
  PASS([c duration] == 3.0, "a copy keeps the duration");
  PASS([c repeatCount] == 2.0, "a copy keeps the repeat count");

  /* The properties a subclass adds are copied too, not just the ones
     CAAnimation itself declares. */
  testHopeful = YES;
  PASS([[c keyPath] isEqualToString: @"position"], "a copy keeps the key path");
  PASS([[c toValue] intValue] == 7, "a copy keeps the to value");
  testHopeful = NO;
  [c release];

  END_SET("copying an animation")

  [pool release];
  return 0;
}
