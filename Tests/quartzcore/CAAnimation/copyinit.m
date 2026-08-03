/* A copied animation carries the same bookkeeping a fresh one does.

   This checks an internal guarantee of this implementation rather than
   anything Apple promises: adding one animation to the same layer twice
   raises here, and a copy that was never initialised would not notice.
   Apple does not raise, so this file is not run against it. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CALayer.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("a copied animation keeps its own bookkeeping")

  CABasicAnimation *b = [CABasicAnimation animation];
  CABasicAnimation *c;
  CALayer *l = [CALayer layer];
  BOOL raised = NO;

  [b setKeyPath: @"opacity"];
  c = [b copy];

  [l addAnimation: c forKey: @"first"];
  @try
    {
      [l addAnimation: c forKey: @"second"];
    }
  @catch (NSException *e)
    {
      raised = YES;
    }

  PASS(raised, "a copy still notices being added to one layer twice");
  [c release];

  END_SET("a copied animation keeps its own bookkeeping")

  [pool release];
  return 0;
}
