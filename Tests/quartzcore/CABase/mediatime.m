/* What CACurrentMediaTime() measures, and how it moves.
   Expected values checked against Apple QuartzCore, where media time reads
   the same as NSProcessInfo's systemUptime and not the wall clock.

   A test cannot set the system clock, so the check below is that media time
   is a time since the machine started rather than seconds since 1970. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <math.h>

#import <QuartzCore/CABase.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what media time measures")

  CFTimeInterval media = CACurrentMediaTime();
  NSTimeInterval wall = [[NSDate date] timeIntervalSince1970];

  PASS(media > 0, "media time is positive");
  PASS(!isinf(media) && !isnan(media), "media time is a real number");

  /* On Apple the two readings are 1.79e9 apart. */
  testHopeful = YES;
  PASS(wall - media > 365.0 * 24 * 60 * 60,
       "media time is not the wall clock");
  testHopeful = NO;

  END_SET("what media time measures")

  START_SET("how media time moves")

  CFTimeInterval before, after;
  int i, backwards = 0;

  before = CACurrentMediaTime();
  for (i = 0; i < 200000; i++)
    {
      after = CACurrentMediaTime();
      if (after < before)
        {
          backwards++;
        }
      before = after;
    }
  PASS(backwards == 0, "media time never goes backwards");

  before = CACurrentMediaTime();
  [NSThread sleepForTimeInterval: 0.1];
  after = CACurrentMediaTime();

  PASS(after - before >= 0.09,
       "media time counts a tenth of a second spent asleep");
  PASS(after - before < 10.0,
       "media time counts the sleep in seconds");

  END_SET("how media time moves")

  START_SET("how finely media time is measured")

  CFTimeInterval smallest = 1.0;
  int trial;

  /* The smallest step over many trials; one trial can be interrupted by
     the scheduler. */
  for (trial = 0; trial < 200; trial++)
    {
      CFTimeInterval t0 = CACurrentMediaTime();
      CFTimeInterval t1 = t0;

      while (t1 == t0)
        {
          t1 = CACurrentMediaTime();
        }
      if (t1 - t0 < smallest)
        {
          smallest = t1 - t0;
        }
    }
  PASS(smallest < 0.001,
       "media time resolves a step shorter than a millisecond");

  END_SET("how finely media time is measured")

  [pool release];
  return 0;
}
