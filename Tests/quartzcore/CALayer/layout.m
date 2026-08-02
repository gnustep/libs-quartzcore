/* When a layer decides it needs laying out again.
   Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>

@interface QCLayoutManager : NSObject
{
  int _count;
}
- (int) count;
@end

@implementation QCLayoutManager

- (void) layoutSublayersOfLayer: (CALayer *)layer
{
  _count++;
}

- (int) count
{
  return _count;
}

@end

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the flag that says a layer wants laying out")

  CALayer *l = [CALayer layer];

  PASS([l needsLayout] == NO, "a fresh layer does not want laying out");

  [l setNeedsLayout];
  PASS([l needsLayout] == YES, "asking for layout sets the flag");

  [l layoutIfNeeded];
  PASS([l needsLayout] == NO, "laying out when needed clears it");

  [l setNeedsLayout];
  [l layoutSublayers];
  PASS([l needsLayout] == YES,
       "laying the sublayers out does not clear it by itself");

  END_SET("the flag that says a layer wants laying out")

  START_SET("who is asked to do the laying out")

  CALayer *l = [CALayer layer];
  QCLayoutManager *m = [[[QCLayoutManager alloc] init] autorelease];

  PASS([l layoutManager] == nil, "a layer starts with no layout manager");

  [l setLayoutManager: m];
  [l setNeedsLayout];
  [l layoutIfNeeded];
  PASS([m count] == 1, "the layout manager is asked to lay the sublayers out");

  END_SET("who is asked to do the laying out")

  START_SET("laying out a tree")

  CALayer *root = [CALayer layer];
  CALayer *child = [CALayer layer];
  QCLayoutManager *rootManager = [[[QCLayoutManager alloc] init] autorelease];
  QCLayoutManager *childManager = [[[QCLayoutManager alloc] init] autorelease];

  [root setLayoutManager: rootManager];
  [child setLayoutManager: childManager];
  [root addSublayer: child];

  [root setNeedsLayout];
  [child setNeedsLayout];

  /* Asking the child lays out from the highest layer that wants it. */
  [child layoutIfNeeded];

  PASS([root needsLayout] == NO, "the layer above is laid out as well");
  PASS([child needsLayout] == NO, "and so is the one asked");
  PASS([rootManager count] == 1 && [childManager count] == 1,
       "each of them lays its own sublayers out once");

  END_SET("laying out a tree")

  /* A layer whose sublayers have changed has them to arrange again. */
  START_SET("what makes a layer want laying out")

  CALayer *root = [CALayer layer];
  CALayer *first = [CALayer layer];

  [root setBounds: CGRectMake(0, 0, 100, 100)];
  [root addSublayer: first];
  [root layoutIfNeeded];
  PASS([root needsLayout] == NO, "a layer just laid out is settled");

  [root addSublayer: [CALayer layer]];
  PASS([root needsLayout] == YES, "adding a sublayer unsettles it");

  [root layoutIfNeeded];
  [root insertSublayer: [CALayer layer] atIndex: 0];
  PASS([root needsLayout] == YES, "so does inserting one at an index");

  [root layoutIfNeeded];
  [root insertSublayer: [CALayer layer] below: first];
  PASS([root needsLayout] == YES, "and inserting one below another");

  [root layoutIfNeeded];
  [root insertSublayer: [CALayer layer] above: first];
  PASS([root needsLayout] == YES, "and inserting one above another");

  [root layoutIfNeeded];
  [first removeFromSuperlayer];
  PASS([root needsLayout] == YES,
       "a sublayer taking itself away unsettles the layer it leaves");

  [root layoutIfNeeded];
  [root setBounds: CGRectMake(0, 0, 200, 200)];
  PASS([root needsLayout] == YES, "and so does its own bounds changing");

  CALayer *newcomer = [CALayer layer];

  [newcomer layoutIfNeeded];
  [root addSublayer: newcomer];
  PASS([newcomer needsLayout] == NO,
       "though the layer that was added is not itself unsettled");

  END_SET("what makes a layer want laying out")

  [pool release];
  return 0;
}
