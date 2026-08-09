/* What a CAConstraint holds, and how a layer holds its constraints.

   The expected values are the ones Apple QuartzCore produces.  Apple declares
   these classes in a header of another name, so the umbrella is imported
   rather than QuartzCore/CAConstraint.h. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/QuartzCore.h>

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what a constraint was made with")

  CAConstraint *c = [CAConstraint constraintWithAttribute: kCAConstraintMidX
                                               relativeTo: @"superlayer"
                                                attribute: kCAConstraintMidY];

  PASS(c != nil, "a constraint is made by the three argument form");
  PASS([c attribute] == kCAConstraintMidX, "it holds the attribute given");
  PASS([c sourceAttribute] == kCAConstraintMidY,
       "and the attribute it is measured against");
  PASS([[c sourceName] isEqualToString: @"superlayer"],
       "and the name of what it is measured against");
  PASS([c scale] == 1.0, "the scale of that form is one");
  PASS([c offset] == 0.0, "and its offset is zero");

  END_SET("what a constraint was made with")

  START_SET("the scale and the offset")

  CAConstraint *withOffset =
    [CAConstraint constraintWithAttribute: kCAConstraintMinX
                               relativeTo: @"other"
                                attribute: kCAConstraintMaxX
                                   offset: 7.0];
  CAConstraint *withBoth =
    [CAConstraint constraintWithAttribute: kCAConstraintMinX
                               relativeTo: @"other"
                                attribute: kCAConstraintMaxX
                                    scale: 0.25
                                   offset: 7.0];

  PASS([withOffset offset] == 7.0, "the four argument form takes an offset");
  PASS([withOffset scale] == 1.0, "and leaves the scale at one");
  PASS([withBoth scale] == 0.25 && [withBoth offset] == 7.0,
       "the five argument form takes both");

  END_SET("the scale and the offset")

  START_SET("the attributes of the two axes")

  /* The four horizontal attributes come before the four vertical ones. */
  PASS(kCAConstraintMinX < kCAConstraintMidX
       && kCAConstraintMidX < kCAConstraintMaxX
       && kCAConstraintMaxX < kCAConstraintWidth,
       "the horizontal attributes run from the left edge to the width");
  PASS(kCAConstraintWidth < kCAConstraintMinY
       && kCAConstraintMinY < kCAConstraintMidY
       && kCAConstraintMidY < kCAConstraintMaxY
       && kCAConstraintMaxY < kCAConstraintHeight,
       "and the vertical ones follow in the same order");

  END_SET("the attributes of the two axes")

  START_SET("a layer's name")

  CALayer *layer = [CALayer layer];

  PASS([layer name] == nil, "a layer has no name to begin with");

  [layer setName: @"a"];

  PASS([[layer name] isEqualToString: @"a"], "and takes the one it is given");

  END_SET("a layer's name")

  START_SET("the constraints a layer holds")

  CALayer *layer = [CALayer layer];
  CAConstraint *c = [CAConstraint constraintWithAttribute: kCAConstraintMinX
                                               relativeTo: @"superlayer"
                                                attribute: kCAConstraintMinX];
  NSMutableArray *given = [NSMutableArray arrayWithObject: c];

  PASS([layer constraints] == nil, "a layer holds no constraints to begin with");

  [layer setConstraints: given];

  PASS([[layer constraints] count] == 1, "it holds the ones it is given");
  PASS([[layer constraints] objectAtIndex: 0] == c, "the constraints themselves");

  [given removeAllObjects];

  PASS([[layer constraints] count] == 1,
       "the array is copied, so emptying the original leaves the layer alone");

  [layer setConstraints: nil];

  PASS([layer constraints] == nil, "and the layer can be emptied again");

  END_SET("the constraints a layer holds")

  START_SET("adding one constraint at a time")

  CALayer *layer = [CALayer layer];
  CAConstraint *first = [CAConstraint constraintWithAttribute: kCAConstraintMinX
                                                   relativeTo: @"superlayer"
                                                    attribute: kCAConstraintMinX];
  CAConstraint *second = [CAConstraint constraintWithAttribute: kCAConstraintMinY
                                                    relativeTo: @"superlayer"
                                                     attribute: kCAConstraintMinY];

  [layer addConstraint: first];

  PASS([[layer constraints] count] == 1,
       "adding to a layer that holds none makes a set of one");

  [layer addConstraint: second];

  PASS([[layer constraints] count] == 2, "and adding again appends");
  PASS([[layer constraints] objectAtIndex: 0] == first
       && [[layer constraints] objectAtIndex: 1] == second,
       "in the order they were added");

  END_SET("adding one constraint at a time")

  START_SET("adding a constraint asks for a layout")

  CALayer *root = [CALayer layer];
  CALayer *child = [CALayer layer];

  [root addSublayer: child];
  [root setNeedsLayout];
  [root layoutIfNeeded];
  [child addConstraint:
    [CAConstraint constraintWithAttribute: kCAConstraintMinX
                               relativeTo: @"superlayer"
                                attribute: kCAConstraintMinX]];

  PASS([root needsLayout],
       "the superlayer is the one asked to lay out again");

  END_SET("adding a constraint asks for a layout")

  [pool release];
  return 0;
}
