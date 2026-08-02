/* Converting points and rectangles between layers, and the affine part of a
   layer transform.  Expected values checked against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <math.h>

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CATransform3D.h>

#define TOL 1e-4

static BOOL
pointIs(CGPoint p, CGFloat x, CGFloat y)
{
  return (fabs(p.x - x) < TOL && fabs(p.y - y) < TOL) ? YES : NO;
}

static BOOL
rectIs(CGRect r, CGFloat x, CGFloat y, CGFloat w, CGFloat h)
{
  return (fabs(r.origin.x - x) < TOL && fabs(r.origin.y - y) < TOL
       && fabs(r.size.width - w) < TOL && fabs(r.size.height - h) < TOL)
    ? YES : NO;
}

static BOOL
affineIs(CGAffineTransform t, CGFloat a, CGFloat b, CGFloat c, CGFloat d,
         CGFloat tx, CGFloat ty)
{
  return (fabs(t.a - a) < TOL && fabs(t.b - b) < TOL
       && fabs(t.c - c) < TOL && fabs(t.d - d) < TOL
       && fabs(t.tx - tx) < TOL && fabs(t.ty - ty) < TOL) ? YES : NO;
}

static CALayer *
layerWithBounds(CGRect bounds, CGPoint position)
{
  CALayer *l = [CALayer layer];

  [l setBounds: bounds];
  [l setPosition: position];
  return l;
}

int
main(int argc, char **argv)
{
  START_SET("a point between a layer and its superlayer")
    CALayer *parent = layerWithBounds(CGRectMake(0, 0, 200, 200),
                                      CGPointMake(100, 100));
    CALayer *child = layerWithBounds(CGRectMake(0, 0, 50, 50),
                                     CGPointMake(100, 50));

    [parent addSublayer: child];

    PASS(pointIs([child convertPoint: CGPointMake(0, 0) toLayer: parent],
                 75, 25),
      "the child origin lands at its offset in the parent");
    PASS(pointIs([child convertPoint: CGPointMake(50, 50) toLayer: parent],
                 125, 75),
      "the far corner of the child lands past it");
    PASS(pointIs([parent convertPoint: CGPointMake(0, 0) toLayer: child],
                 -75, -25),
      "the parent origin lands before the child origin");
    PASS(pointIs([child convertPoint: CGPointMake(0, 0) fromLayer: parent],
                 -75, -25),
      "converting from the parent is the same as the parent converting to it");
    PASS(pointIs([parent convertPoint: CGPointMake(0, 0) fromLayer: child],
                 75, 25),
      "converting from the child is the same as the child converting to it");
  END_SET("a point between a layer and its superlayer")

  START_SET("a rectangle between a layer and its superlayer")
    CALayer *parent = layerWithBounds(CGRectMake(0, 0, 200, 200),
                                      CGPointMake(100, 100));
    CALayer *child = layerWithBounds(CGRectMake(0, 0, 50, 50),
                                     CGPointMake(100, 50));

    [parent addSublayer: child];

    PASS(rectIs([child convertRect: CGRectMake(0, 0, 10, 20) toLayer: parent],
                75, 25, 10, 20),
      "a rectangle keeps its size and moves by the offset");
    PASS(rectIs([parent convertRect: CGRectMake(0, 0, 10, 20) toLayer: child],
                -75, -25, 10, 20),
      "and the same the other way");
  END_SET("a rectangle between a layer and its superlayer")

  START_SET("a layer converts to itself unchanged")
    CALayer *l = layerWithBounds(CGRectMake(0, 0, 50, 50),
                                 CGPointMake(100, 50));

    PASS(pointIs([l convertPoint: CGPointMake(3, 4) toLayer: l], 3, 4),
      "a point converted to the same layer is unchanged");
    PASS(rectIs([l convertRect: CGRectMake(3, 4, 5, 6) toLayer: l], 3, 4, 5, 6),
      "a rectangle converted to the same layer is unchanged");
  END_SET("a layer converts to itself unchanged")

  START_SET("the superlayer bounds origin does not move a child")
    CALayer *parent = layerWithBounds(CGRectMake(10, 20, 200, 200),
                                      CGPointMake(100, 100));
    CALayer *child = layerWithBounds(CGRectMake(0, 0, 50, 50),
                                     CGPointMake(100, 50));

    [parent addSublayer: child];

    PASS(pointIs([child convertPoint: CGPointMake(0, 0) toLayer: parent],
                 75, 25),
      "a bounds origin on the parent leaves the conversion alone");
  END_SET("the superlayer bounds origin does not move a child")

  START_SET("the layer's own transform applies")
    CALayer *parent = layerWithBounds(CGRectMake(0, 0, 200, 200),
                                      CGPointMake(100, 100));
    CALayer *child = layerWithBounds(CGRectMake(0, 0, 50, 50),
                                     CGPointMake(100, 50));

    [child setTransform: CATransform3DMakeScale(2, 2, 1)];
    [parent addSublayer: child];

    PASS(pointIs([child convertPoint: CGPointMake(0, 0) toLayer: parent],
                 50, 0),
      "a scaled child spreads its origin away from the anchor point");
    PASS(pointIs([child convertPoint: CGPointMake(50, 50) toLayer: parent],
                 150, 100),
      "and its far corner the other way");
    PASS(rectIs([child convertRect: CGRectMake(0, 0, 10, 20) toLayer: parent],
                50, 0, 20, 40),
      "a rectangle is scaled as well as moved");
  END_SET("the layer's own transform applies")

  START_SET("the superlayer's sublayer transform applies")
    CALayer *parent = layerWithBounds(CGRectMake(0, 0, 200, 200),
                                      CGPointMake(100, 100));
    CALayer *child = layerWithBounds(CGRectMake(0, 0, 50, 50),
                                     CGPointMake(100, 50));

    [parent setSublayerTransform: CATransform3DMakeTranslation(10, 20, 0)];
    [parent addSublayer: child];

    PASS(pointIs([child convertPoint: CGPointMake(0, 0) toLayer: parent],
                 85, 45),
      "the sublayer transform of the parent moves the child");
  END_SET("the superlayer's sublayer transform applies")

  START_SET("a sublayer transform and a child transform together")
    CALayer *parent = layerWithBounds(CGRectMake(0, 0, 200, 200),
                                      CGPointMake(100, 100));
    CALayer *child = layerWithBounds(CGRectMake(0, 0, 50, 50),
                                     CGPointMake(100, 50));

    [parent setSublayerTransform: CATransform3DMakeScale(2, 2, 1)];
    [child setTransform: CATransform3DMakeTranslation(5, 6, 0)];
    [parent addSublayer: child];

    /* The sublayer transform applies about the parent's anchor point, so the
       child is thrown well outside the parent's bounds. */
    PASS(pointIs([child convertPoint: CGPointMake(0, 0) toLayer: parent],
                 60, -38),
      "both transforms apply, the parent's about its anchor point");
  END_SET("a sublayer transform and a child transform together")

  START_SET("a rotated child converts a rectangle to its bounding box")
    CALayer *parent = layerWithBounds(CGRectMake(0, 0, 200, 200),
                                      CGPointMake(100, 100));
    CALayer *child = layerWithBounds(CGRectMake(0, 0, 100, 100),
                                     CGPointMake(100, 100));

    [child setTransform: CATransform3DMakeRotation(M_PI / 4, 0, 0, 1)];
    [parent addSublayer: child];

    PASS(rectIs([child convertRect: CGRectMake(0, 0, 100, 100) toLayer: parent],
                100 - 50 * M_SQRT2, 100 - 50 * M_SQRT2,
                100 * M_SQRT2, 100 * M_SQRT2),
      "the rectangle of a rotated layer is the box its corners span");
    PASS(pointIs([child convertPoint: CGPointMake(50, 50) toLayer: parent],
                 100, 100),
      "the centre of a rotated layer stays where it is");
  END_SET("a rotated child converts a rectangle to its bounding box")

  START_SET("conversions across the tree")
    CALayer *g0 = layerWithBounds(CGRectMake(0, 0, 400, 400),
                                  CGPointMake(200, 200));
    CALayer *g1 = layerWithBounds(CGRectMake(0, 0, 200, 200),
                                  CGPointMake(100, 100));
    CALayer *g2 = layerWithBounds(CGRectMake(0, 0, 50, 50),
                                  CGPointMake(25, 25));
    CALayer *parent = layerWithBounds(CGRectMake(0, 0, 200, 200),
                                      CGPointMake(100, 100));
    CALayer *s1 = layerWithBounds(CGRectMake(0, 0, 50, 50),
                                  CGPointMake(25, 25));
    CALayer *s2 = layerWithBounds(CGRectMake(0, 0, 50, 50),
                                  CGPointMake(125, 25));

    [g0 addSublayer: g1];
    [g1 addSublayer: g2];
    [parent addSublayer: s1];
    [parent addSublayer: s2];

    PASS(pointIs([g2 convertPoint: CGPointMake(0, 0) toLayer: g0], 0, 0),
      "a grandchild converts through both of its parents");
    PASS(pointIs([g0 convertPoint: CGPointMake(0, 0) toLayer: g2], 0, 0),
      "and back down again");
    PASS(pointIs([s1 convertPoint: CGPointMake(0, 0) toLayer: s2], -100, 0),
      "one sibling converts into the other");
  END_SET("conversions across the tree")

  START_SET("layers that share no tree")
    CALayer *u1 = layerWithBounds(CGRectMake(0, 0, 50, 50),
                                  CGPointMake(25, 25));
    CALayer *u2 = layerWithBounds(CGRectMake(0, 0, 50, 50),
                                  CGPointMake(500, 500));
    CALayer *parent = layerWithBounds(CGRectMake(0, 0, 200, 200),
                                      CGPointMake(100, 100));
    CALayer *d = layerWithBounds(CGRectMake(0, 0, 50, 50),
                                 CGPointMake(100, 50));

    PASS(pointIs([u1 convertPoint: CGPointMake(0, 0) toLayer: u2], -475, -475),
      "two layers in different trees convert through the root of each");

    [parent addSublayer: d];
    PASS(pointIs([d convertPoint: CGPointMake(0, 0) toLayer: parent], 75, 25),
      "an attached layer converts through its parent");
    [d removeFromSuperlayer];
    PASS(pointIs([d convertPoint: CGPointMake(0, 0) toLayer: parent], 75, 25),
      "a detached layer converts as if it were a root of its own");
  END_SET("layers that share no tree")

  START_SET("the affine part of the transform")
    CALayer *l = [CALayer layer];
    CATransform3D perspective = CATransform3DIdentity;

    PASS(affineIs([l affineTransform], 1, 0, 0, 1, 0, 0),
      "a new layer reports the identity");

    [l setTransform: CATransform3DMakeScale(2, 3, 1)];
    PASS(affineIs([l affineTransform], 2, 0, 0, 3, 0, 0),
      "a two-dimensional scale is reported as itself");

    [l setTransform: CATransform3DMakeTranslation(3, 4, 0)];
    PASS(affineIs([l affineTransform], 1, 0, 0, 1, 3, 4),
      "a two-dimensional translation is reported as itself");

    [l setTransform: CATransform3DMakeRotation(M_PI / 4, 0, 0, 1)];
    PASS(affineIs([l affineTransform], M_SQRT1_2, M_SQRT1_2,
                  -M_SQRT1_2, M_SQRT1_2, 0, 0),
      "a rotation about z is reported as itself");

    /* A transform that is not affine has no affine equivalent, and the
       identity is reported rather than the elements in those places. */
    [l setTransform: CATransform3DMakeScale(2, 3, 4)];
    PASS(affineIs([l affineTransform], 1, 0, 0, 1, 0, 0),
      "a scale in z reports the identity");

    [l setTransform: CATransform3DMakeRotation(M_PI / 2, 1, 0, 0)];
    PASS(affineIs([l affineTransform], 1, 0, 0, 1, 0, 0),
      "a rotation about x reports the identity");

    [l setTransform: CATransform3DMakeTranslation(0, 0, 5)];
    PASS(affineIs([l affineTransform], 1, 0, 0, 1, 0, 0),
      "a translation in z reports the identity");

    perspective.m34 = -1.0 / 500;
    [l setTransform: perspective];
    PASS(affineIs([l affineTransform], 1, 0, 0, 1, 0, 0),
      "a perspective transform reports the identity");
  END_SET("the affine part of the transform")

  START_SET("setting the affine transform")
    CALayer *l = [CALayer layer];
    CATransform3D t;

    [l setAffineTransform: CGAffineTransformMake(2, 3, 4, 5, 6, 7)];
    PASS(affineIs([l affineTransform], 2, 3, 4, 5, 6, 7),
      "the affine transform reads back what was set");

    t = [l transform];
    PASS(t.m11 == 2 && t.m12 == 3 && t.m21 == 4 && t.m22 == 5
      && t.m41 == 6 && t.m42 == 7 && t.m33 == 1 && t.m44 == 1,
      "it is held in the six places of the layer transform");

    /* Setting it replaces the transform rather than concatenating with it. */
    [l setTransform: CATransform3DMakeScale(9, 9, 9)];
    [l setAffineTransform: CGAffineTransformMakeTranslation(1, 2)];
    PASS(affineIs([l affineTransform], 1, 0, 0, 1, 1, 2),
      "setting it replaces the transform that was there");
    t = [l transform];
    PASS(t.m33 == 1, "the z scale of the replaced transform is gone");
  END_SET("setting the affine transform")

  return 0;
}
