/* What makes a layer want laying out again.

   The expected values are the ones Apple QuartzCore produces. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/QuartzCore.h>

/* A superlayer with one sublayer already, laid out and settled. */
static CALayer *
settled(CALayer **existing)
{
  CALayer *root = [CALayer layer];
  CALayer *first = [CALayer layer];

  [root setBounds: CGRectMake(0, 0, 100, 100)];
  [root addSublayer: first];
  [root layoutIfNeeded];
  if (existing != NULL)
    {
      *existing = first;
    }
  return root;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("a layer on its own")

  CALayer *layer = [CALayer layer];

  PASS(![layer needsLayout], "a fresh layer does not want laying out");

  [layer setNeedsLayout];

  PASS([layer needsLayout], "and wants it once it is asked to");

  [layer layoutIfNeeded];

  PASS(![layer needsLayout], "laying it out settles it again");

  END_SET("a layer on its own")

  START_SET("a settled superlayer")

  CALayer *root = settled(NULL);

  PASS(![root needsLayout], "a superlayer that has been laid out is settled");

  END_SET("a settled superlayer")

  START_SET("adding a sublayer")

  CALayer *root = settled(NULL);
  CALayer *added = [CALayer layer];

  [added layoutIfNeeded];
  [root addSublayer: added];

  PASS([root needsLayout], "the superlayer wants laying out again");
  PASS(![added needsLayout], "the layer that was added does not");

  END_SET("adding a sublayer")

  START_SET("inserting a sublayer")

  CALayer *root = settled(NULL);

  [root insertSublayer: [CALayer layer] atIndex: 0];

  PASS([root needsLayout], "inserting at an index wants laying out");

  END_SET("inserting a sublayer")

  START_SET("inserting below a sibling")

  CALayer *first;
  CALayer *root = settled(&first);

  [root insertSublayer: [CALayer layer] below: first];

  PASS([root needsLayout], "inserting below a sibling wants laying out");

  END_SET("inserting below a sibling")

  START_SET("inserting above a sibling")

  CALayer *first;
  CALayer *root = settled(&first);

  [root insertSublayer: [CALayer layer] above: first];

  PASS([root needsLayout], "inserting above a sibling wants laying out");

  END_SET("inserting above a sibling")

  START_SET("a sublayer leaving")

  CALayer *first;
  CALayer *root = settled(&first);

  [first removeFromSuperlayer];

  PASS([root needsLayout],
       "the superlayer a sublayer left wants laying out");

  END_SET("a sublayer leaving")

  START_SET("replacing the sublayers outright")

  CALayer *root = settled(NULL);

  [root setSublayers: [NSArray arrayWithObject: [CALayer layer]]];

  PASS([root needsLayout], "setting the sublayers wants laying out");

  END_SET("replacing the sublayers outright")

  START_SET("adding to sublayers that were set outright")

  CALayer *root = settled(NULL);
  CALayer *added = [CALayer layer];

  [root setSublayers: [NSArray arrayWithObject: [CALayer layer]]];

  PASS_RUNS([root addSublayer: added];,
            "a layer can be added after the sublayers were set outright")
  PASS([[root sublayers] count] == 2,
       "and it joins the one that was set");
  PASS([added superlayer] == root, "with this layer as its superlayer");

  END_SET("adding to sublayers that were set outright")

  START_SET("the bounds changing")

  CALayer *root = settled(NULL);

  [root setBounds: CGRectMake(0, 0, 200, 200)];

  PASS([root needsLayout],
       "a layer whose bounds changed wants laying out, since its sublayers "
       "are placed inside them");

  END_SET("the bounds changing")

  [pool release];
  return 0;
}
