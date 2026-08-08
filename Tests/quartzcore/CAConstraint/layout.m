/* What CAConstraintLayoutManager does to the frames of the sublayers.

   Every expected frame here was measured against Apple QuartzCore.  The
   superlayer's bounds are (0,0,200,100) throughout, so its minX is 0, its
   midX 100, its maxX 200 and its width 200, and each sublayer starts at
   (3,5,40,20). */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <math.h>

#import <QuartzCore/QuartzCore.h>

#define CLOSE(a, b) (fabs((double)(a) - (double)(b)) < 1e-4)

static CAConstraint *
c3(CAConstraintAttribute a, NSString *src, CAConstraintAttribute sa)
{
  return [CAConstraint constraintWithAttribute: a relativeTo: src attribute: sa];
}

static CAConstraint *
c4(CAConstraintAttribute a, NSString *src, CAConstraintAttribute sa,
   CGFloat offset)
{
  return [CAConstraint constraintWithAttribute: a relativeTo: src
                                     attribute: sa offset: offset];
}

static CAConstraint *
c5(CAConstraintAttribute a, NSString *src, CAConstraintAttribute sa,
   CGFloat scale, CGFloat offset)
{
  return [CAConstraint constraintWithAttribute: a relativeTo: src
                                     attribute: sa scale: scale offset: offset];
}

static CALayer *
rootLayer(void)
{
  CALayer *root = [CALayer layer];

  [root setBounds: CGRectMake(0, 0, 200, 100)];
  [root setLayoutManager: [CAConstraintLayoutManager layoutManager]];
  return root;
}

/* One sublayer under the constraints given, laid out, and its frame. */
static CGRect
laidOut(NSArray *constraints)
{
  CALayer *root = rootLayer();
  CALayer *child = [CALayer layer];

  [child setName: @"child"];
  [child setFrame: CGRectMake(3, 5, 40, 20)];
  [root addSublayer: child];
  [child setConstraints: constraints];
  [root layoutSublayers];
  return [child frame];
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the shared layout manager")

  PASS([CAConstraintLayoutManager layoutManager] != nil,
       "a layout manager is made by +layoutManager");
  PASS([CAConstraintLayoutManager layoutManager] ==
       [CAConstraintLayoutManager layoutManager],
       "and it is the same one every time");

  END_SET("the shared layout manager")

  START_SET("one constraint on an axis keeps the size the layer has")

  CGRect min = laidOut([NSArray arrayWithObject:
    c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX)]);
  CGRect mid = laidOut([NSArray arrayWithObject:
    c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidX)]);
  CGRect max = laidOut([NSArray arrayWithObject:
    c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX)]);

  PASS(CLOSE(min.origin.x, 0) && CLOSE(min.size.width, 40),
       "a left edge on the superlayer's puts it there and keeps the width");
  PASS(CLOSE(mid.origin.x, 80), "a centre on the superlayer's centres it");
  PASS(CLOSE(max.origin.x, 160), "a right edge on the superlayer's ends it there");
  PASS(CLOSE(min.origin.y, 5) && CLOSE(min.size.height, 20),
       "and the axis with no constraints is left alone");

  END_SET("one constraint on an axis keeps the size the layer has")

  START_SET("the vertical axis runs from the bottom")

  CGRect min = laidOut([NSArray arrayWithObject:
    c3(kCAConstraintMinY, @"superlayer", kCAConstraintMinY)]);
  CGRect max = laidOut([NSArray arrayWithObject:
    c3(kCAConstraintMaxY, @"superlayer", kCAConstraintMaxY)]);

  PASS(CLOSE(min.origin.y, 0), "the minimum edge is the bottom one");
  PASS(CLOSE(max.origin.y, 80), "and the maximum edge the top");

  END_SET("the vertical axis runs from the bottom")

  START_SET("a size on its own does nothing")

  CGRect f = laidOut([NSArray arrayWithObject:
    c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.5, 0)]);

  PASS(CLOSE(f.origin.x, 3) && CLOSE(f.size.width, 40),
       "a width with no edge to put it against leaves the layer alone");

  END_SET("a size on its own does nothing")

  START_SET("two constraints on an axis")

  CGRect minMax = laidOut([NSArray arrayWithObjects:
    c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX),
    c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX), nil]);
  CGRect minWidth = laidOut([NSArray arrayWithObjects:
    c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX),
    c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.5, 0), nil]);
  CGRect maxWidth = laidOut([NSArray arrayWithObjects:
    c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX),
    c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.5, 0), nil]);
  CGRect midWidth = laidOut([NSArray arrayWithObjects:
    c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidX),
    c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.5, 0), nil]);
  CGRect minMid = laidOut([NSArray arrayWithObjects:
    c4(kCAConstraintMinX, @"superlayer", kCAConstraintMinX, 20),
    c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidX), nil]);
  CGRect midMax = laidOut([NSArray arrayWithObjects:
    c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidX),
    c4(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX, -20), nil]);

  PASS(CLOSE(minMax.origin.x, 0) && CLOSE(minMax.size.width, 200),
       "two edges stretch the layer between them");
  PASS(CLOSE(minWidth.origin.x, 0) && CLOSE(minWidth.size.width, 100),
       "a left edge and a width put it there at that width");
  PASS(CLOSE(maxWidth.origin.x, 100) && CLOSE(maxWidth.size.width, 100),
       "a right edge and a width end it there");
  PASS(CLOSE(midWidth.origin.x, 50) && CLOSE(midWidth.size.width, 100),
       "a centre and a width centre it");
  PASS(CLOSE(minMid.origin.x, 20) && CLOSE(minMid.size.width, 160),
       "a left edge and a centre give twice the distance between them");
  PASS(CLOSE(midMax.origin.x, 20) && CLOSE(midMax.size.width, 160),
       "and so do a centre and a right edge");

  END_SET("two constraints on an axis")

  START_SET("more relationships than an axis needs")

  /* The one given last decides the axis, and it is paired with the lowest
     of the others: the left edge before the centre, the centre before the
     right edge, and any of them before a width. */
  CGRect a = laidOut([NSArray arrayWithObjects:
    c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX),
    c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX),
    c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.25, 0), nil]);
  CGRect b = laidOut([NSArray arrayWithObjects:
    c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX),
    c4(kCAConstraintMidX, @"superlayer", kCAConstraintMidX, -30),
    c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.25, 0), nil]);
  CGRect c = laidOut([NSArray arrayWithObjects:
    c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.25, 0),
    c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX),
    c4(kCAConstraintMidX, @"superlayer", kCAConstraintMidX, -30), nil]);
  CGRect d = laidOut([NSArray arrayWithObjects:
    c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX),
    c4(kCAConstraintMidX, @"superlayer", kCAConstraintMidX, -30),
    c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX), nil]);
  CGRect e = laidOut([NSArray arrayWithObjects:
    c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX),
    c4(kCAConstraintMidX, @"superlayer", kCAConstraintMidX, -30),
    c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX),
    c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.25, 0), nil]);

  PASS(CLOSE(a.origin.x, 0) && CLOSE(a.size.width, 50),
       "a width given last takes the left edge as the other relationship");
  PASS(CLOSE(b.origin.x, 45) && CLOSE(b.size.width, 50),
       "and the centre where there is no left edge");
  PASS(CLOSE(c.origin.x, -60) && CLOSE(c.size.width, 260),
       "a centre given last takes the right edge over a width");
  PASS(CLOSE(d.origin.x, 0) && CLOSE(d.size.width, 140),
       "a left edge given last takes the centre over the right edge");
  PASS(CLOSE(e.origin.x, 0) && CLOSE(e.size.width, 50),
       "all four together come to the left edge and the width");

  END_SET("more relationships than an axis needs")

  START_SET("relationships that describe nothing")

  CGRect twice = laidOut([NSArray arrayWithObjects:
    c4(kCAConstraintMinX, @"superlayer", kCAConstraintMinX, 10),
    c4(kCAConstraintMinX, @"superlayer", kCAConstraintMinX, 40), nil]);
  CGRect nobody = laidOut([NSArray arrayWithObject:
    c3(kCAConstraintMinX, @"nobody", kCAConstraintMinX)]);
  CGRect itself = laidOut([NSArray arrayWithObject:
    c4(kCAConstraintMinX, @"child", kCAConstraintMinX, 10)]);

  PASS(CLOSE(twice.origin.x, 3) && CLOSE(twice.size.width, 40),
       "the same edge twice leaves the axis alone, taking neither value");
  PASS(CLOSE(nobody.origin.x, 3),
       "a layer of a name nothing answers to leaves it alone");
  PASS(CLOSE(itself.origin.x, 3), "and so does a layer naming itself");

  END_SET("relationships that describe nothing")

  START_SET("the scale and the offset")

  CGRect scaled = laidOut([NSArray arrayWithObject:
    c5(kCAConstraintMinX, @"superlayer", kCAConstraintMaxX, 0.25, 7)]);
  CGRect crossed = laidOut([NSArray arrayWithObject:
    c3(kCAConstraintMinX, @"superlayer", kCAConstraintMaxY)]);

  PASS(CLOSE(scaled.origin.x, 57),
       "the value read is scaled and then offset");
  PASS(CLOSE(crossed.origin.x, 100),
       "and it may be read from the other axis");

  END_SET("the scale and the offset")

  START_SET("the superlayer is measured by its bounds")

  CALayer *root = [CALayer layer];
  CALayer *child = [CALayer layer];
  CGRect f;

  [root setBounds: CGRectMake(30, 70, 200, 100)];
  [root setLayoutManager: [CAConstraintLayoutManager layoutManager]];
  [child setFrame: CGRectMake(3, 5, 40, 20)];
  [root addSublayer: child];
  [child setConstraints: [NSArray arrayWithObjects:
    c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX),
    c3(kCAConstraintMinY, @"superlayer", kCAConstraintMinY), nil]];
  [root layoutSublayers];
  f = [child frame];

  PASS(CLOSE(f.origin.x, 30) && CLOSE(f.origin.y, 70),
       "a layer pinned to the corner of bounds that do not start at zero");

  END_SET("the superlayer is measured by its bounds")

  START_SET("a sibling as the source")

  CALayer *root = rootLayer();
  CALayer *a = [CALayer layer];
  CALayer *b = [CALayer layer];

  [a setName: @"a"];
  [a setFrame: CGRectMake(10, 0, 30, 20)];
  [a setConstraints: [NSArray arrayWithObject:
    c4(kCAConstraintMinX, @"superlayer", kCAConstraintMinX, 10)]];
  [b setName: @"b"];
  [b setFrame: CGRectMake(0, 0, 50, 20)];
  [b setConstraints: [NSArray arrayWithObject:
    c4(kCAConstraintMinX, @"a", kCAConstraintMaxX, 5)]];
  [root addSublayer: a];
  [root addSublayer: b];
  [root layoutSublayers];

  PASS(CLOSE([b frame].origin.x, 45),
       "a layer is placed against the edge of the sibling it names");

  END_SET("a sibling as the source")

  START_SET("a sibling that is not itself laid out")

  /* The source is read from the layout, so a sibling with nothing to lay it
     out on that axis offers nothing to read. */
  CALayer *root = rootLayer();
  CALayer *a = [CALayer layer];
  CALayer *b = [CALayer layer];

  [a setName: @"a"];
  [a setFrame: CGRectMake(10, 0, 30, 20)];
  [b setName: @"b"];
  [b setFrame: CGRectMake(0, 0, 50, 20)];
  [b setConstraints: [NSArray arrayWithObject:
    c4(kCAConstraintMinX, @"a", kCAConstraintMaxX, 5)]];
  [root addSublayer: a];
  [root addSublayer: b];
  [root layoutSublayers];

  PASS(CLOSE([b frame].origin.x, 0),
       "naming a sibling with no constraints of its own leaves the layer alone");

  END_SET("a sibling that is not itself laid out")

  START_SET("a sibling laid out on the other axis only")

  CALayer *root = rootLayer();
  CALayer *a = [CALayer layer];
  CALayer *b = [CALayer layer];

  [a setName: @"a"];
  [a setFrame: CGRectMake(10, 0, 30, 20)];
  [a setConstraints: [NSArray arrayWithObject:
    c3(kCAConstraintMinY, @"superlayer", kCAConstraintMinY)]];
  [b setName: @"b"];
  [b setFrame: CGRectMake(0, 0, 50, 20)];
  [b setConstraints: [NSArray arrayWithObject:
    c4(kCAConstraintMinX, @"a", kCAConstraintMaxX, 5)]];
  [root addSublayer: a];
  [root addSublayer: b];
  [root layoutSublayers];

  PASS(CLOSE([b frame].origin.x, 0),
       "the axis the value is read from is the one that has to be laid out");

  END_SET("a sibling laid out on the other axis only")

  START_SET("the order the sublayers are in does not matter")

  CALayer *root = rootLayer();
  CALayer *a = [CALayer layer];
  CALayer *b = [CALayer layer];

  [a setName: @"a"];
  [a setFrame: CGRectMake(0, 0, 50, 20)];
  [a setConstraints: [NSArray arrayWithObject:
    c3(kCAConstraintMinX, @"superlayer", kCAConstraintMidX)]];
  [b setName: @"b"];
  [b setFrame: CGRectMake(0, 0, 30, 20)];
  [b setConstraints: [NSArray arrayWithObject:
    c4(kCAConstraintMinX, @"a", kCAConstraintMinX, 10)]];
  [root addSublayer: b];
  [root addSublayer: a];
  [root layoutSublayers];

  PASS(CLOSE([a frame].origin.x, 100), "the layer depended on is laid out");
  PASS(CLOSE([b frame].origin.x, 110),
       "and the one that depends on it follows, though it comes first");

  END_SET("the order the sublayers are in does not matter")

  START_SET("constraints that lead in a circle")

  CALayer *root = rootLayer();
  CALayer *a = [CALayer layer];
  CALayer *b = [CALayer layer];

  [a setName: @"a"];
  [a setFrame: CGRectMake(0, 0, 50, 20)];
  [a setConstraints: [NSArray arrayWithObject:
    c4(kCAConstraintMinX, @"b", kCAConstraintMaxX, 1)]];
  [b setName: @"b"];
  [b setFrame: CGRectMake(0, 0, 30, 20)];
  [b setConstraints: [NSArray arrayWithObject:
    c4(kCAConstraintMinX, @"a", kCAConstraintMaxX, 1)]];
  [root addSublayer: a];
  [root addSublayer: b];
  [root layoutSublayers];

  PASS(CLOSE([a frame].origin.x, 0) && CLOSE([b frame].origin.x, 0),
       "two layers waiting on each other are both left where they were");

  END_SET("constraints that lead in a circle")

  START_SET("two sublayers of one superlayer")

  /* The example Apple gives: two layers each half the width, filling their
     superlayer between them. */
  CALayer *root = rootLayer();
  CALayer *left = [CALayer layer];
  CALayer *right = [CALayer layer];
  CAConstraint *height = c3(kCAConstraintHeight, @"superlayer", kCAConstraintHeight);
  CAConstraint *width = c5(kCAConstraintWidth, @"superlayer", kCAConstraintWidth, 0.5, 0);
  CAConstraint *bottom = c3(kCAConstraintMinY, @"superlayer", kCAConstraintMinY);

  [left setName: @"left"];
  [left setFrame: CGRectMake(0, 0, 20, 20)];
  [right setName: @"right"];
  [right setFrame: CGRectMake(0, 0, 20, 20)];
  [root addSublayer: left];
  [root addSublayer: right];
  [left setConstraints: [NSArray arrayWithObjects: height, width, bottom,
    c3(kCAConstraintMinX, @"superlayer", kCAConstraintMinX), nil]];
  [right setConstraints: [NSArray arrayWithObjects: height, width, bottom,
    c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX), nil]];
  [root layoutSublayers];

  PASS(CGRectEqualToRect([left frame], CGRectMake(0, 0, 100, 100)),
       "the first fills the left half");
  PASS(CGRectEqualToRect([right frame], CGRectMake(100, 0, 100, 100)),
       "and the second the right half");

  END_SET("two sublayers of one superlayer")

  START_SET("asking the manager itself")

  CALayer *root = [CALayer layer];
  CALayer *child = [CALayer layer];

  [root setBounds: CGRectMake(0, 0, 200, 100)];
  [child setFrame: CGRectMake(3, 5, 40, 20)];
  [root addSublayer: child];
  [child setConstraints: [NSArray arrayWithObject:
    c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidX)]];
  [[CAConstraintLayoutManager layoutManager] layoutSublayersOfLayer: root];

  PASS(CLOSE([child frame].origin.x, 80),
       "the manager lays a layer's sublayers out without being its own");

  END_SET("asking the manager itself")

  START_SET("laying out what needs it")

  CALayer *root = rootLayer();
  CALayer *child = [CALayer layer];

  [child setFrame: CGRectMake(3, 5, 40, 20)];
  [root addSublayer: child];
  [child setConstraints: [NSArray arrayWithObject:
    c3(kCAConstraintMidX, @"superlayer", kCAConstraintMidX)]];
  [root layoutIfNeeded];

  PASS(CLOSE([child frame].origin.x, 80),
       "adding the constraint asked for the layout that then happened");
  PASS(![root needsLayout], "and the layer no longer wants laying out");

  END_SET("laying out what needs it")

  START_SET("a layout reaches the whole tree")

  CALayer *root = rootLayer();
  CALayer *middle = [CALayer layer];
  CALayer *deep = [CALayer layer];

  [middle setName: @"middle"];
  [middle setFrame: CGRectMake(0, 0, 100, 50)];
  [middle setLayoutManager: [CAConstraintLayoutManager layoutManager]];
  [deep setName: @"deep"];
  [deep setFrame: CGRectMake(1, 1, 10, 10)];
  [root addSublayer: middle];
  [middle addSublayer: deep];
  [deep setConstraints: [NSArray arrayWithObject:
    c3(kCAConstraintMaxX, @"superlayer", kCAConstraintMaxX)]];
  [root layoutIfNeeded];

  PASS(CLOSE([deep frame].origin.x, 90),
       "a layer two levels down is laid out by its own superlayer");

  END_SET("a layout reaches the whole tree")

  [pool release];
  return 0;
}
