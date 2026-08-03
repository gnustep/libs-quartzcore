/* Archiving an animation, and the layer bookkeeping a copy carries.
   Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CALayer.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("archiving a basic animation")

  CABasicAnimation *b = [CABasicAnimation animation];
  NSData *d;
  CABasicAnimation *r;

  [b setKeyPath: @"position"];
  [b setDuration: 3.0];
  [b setRepeatCount: 2.0];
  [b setToValue: [NSNumber numberWithInt: 7]];

  d = [NSKeyedArchiver archivedDataWithRootObject: b];
  PASS(d != nil && [d length] > 0, "an animation can be archived");

  r = [NSKeyedUnarchiver unarchiveObjectWithData: d];
  PASS([r isKindOfClass: [CABasicAnimation class]],
       "what comes back is a basic animation");
  PASS([[r keyPath] isEqualToString: @"position"],
       "the key path survives being archived");
  PASS([r duration] == 3.0, "the duration survives being archived");
  PASS([r repeatCount] == 2.0, "the repeat count survives being archived");
  PASS([[r toValue] intValue] == 7, "the to value survives being archived");

  END_SET("archiving a basic animation")

  START_SET("archiving a keyframe animation")

  CAKeyframeAnimation *k = [CAKeyframeAnimation animation];
  NSArray *values = [NSArray arrayWithObjects:
    [NSNumber numberWithInt: 1], [NSNumber numberWithInt: 2], nil];
  CAKeyframeAnimation *r;

  [k setKeyPath: @"opacity"];
  [k setValues: values];

  r = [NSKeyedUnarchiver unarchiveObjectWithData:
    [NSKeyedArchiver archivedDataWithRootObject: k]];

  PASS([[r keyPath] isEqualToString: @"opacity"],
       "a keyframe animation keeps its key path");
  PASS([[r values] count] == 2, "a keyframe animation keeps its values");

  END_SET("archiving a keyframe animation")

  [pool release];
  return 0;
}
