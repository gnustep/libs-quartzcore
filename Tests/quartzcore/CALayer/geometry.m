/* CALayer geometry: the defaults, the bounds/position/anchorPoint setters, the
   frame derived from them and the sublayer tree.  Expected values checked
   against Apple QuartzCore. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CATransform3D.h>
#include <math.h>

static BOOL eq(CGFloat a, CGFloat b)
{
  CGFloat d = a - b;
  if (d < 0) d = -d;
  return d < 1e-4;
}

static BOOL peq(CGPoint p, CGFloat x, CGFloat y)
{
  return eq(p.x, x) && eq(p.y, y);
}

static BOOL req(CGRect r, CGFloat x, CGFloat y, CGFloat w, CGFloat h)
{
  return eq(r.origin.x, x) && eq(r.origin.y, y)
      && eq(r.size.width, w) && eq(r.size.height, h);
}

static BOOL isIdentity(CATransform3D t)
{
  return eq(t.m11, 1) && eq(t.m12, 0) && eq(t.m13, 0) && eq(t.m14, 0)
      && eq(t.m21, 0) && eq(t.m22, 1) && eq(t.m23, 0) && eq(t.m24, 0)
      && eq(t.m31, 0) && eq(t.m32, 0) && eq(t.m33, 1) && eq(t.m34, 0)
      && eq(t.m41, 0) && eq(t.m42, 0) && eq(t.m43, 0) && eq(t.m44, 1);
}

static void defaults(void)
{
  CALayer *l = [CALayer layer];

  PASS(l != nil, "a layer can be created");
  PASS(req([l bounds], 0, 0, 0, 0), "a new layer has empty bounds");
  PASS(peq([l position], 0, 0), "a new layer sits at the origin");
  PASS(peq([l anchorPoint], 0.5, 0.5),
       "a new layer is anchored at its centre");
  PASS(eq([l anchorPointZ], 0), "a new layer has a zero depth anchor");
  PASS(eq([l zPosition], 0), "a new layer has a zero z position");
  PASS([l masksToBounds] == NO, "a new layer does not mask to its bounds");
  PASS([l isGeometryFlipped] == NO, "a new layer does not flip its geometry");
  PASS([l isHidden] == NO, "a new layer is not hidden");
  PASS(isIdentity([l transform]), "a new layer has the identity transform");
  PASS(isIdentity([l sublayerTransform]),
       "a new layer has the identity sublayer transform");
  PASS([l superlayer] == nil, "a new layer has no superlayer");

  testHopeful = YES;
  PASS(eq([l contentsScale], 1), "a new layer has a contents scale of one");
  testHopeful = NO;
}

static void roundTrips(void)
{
  CALayer *l = [CALayer layer];

  [l setBounds: CGRectMake(1, 2, 3, 4)];
  PASS(req([l bounds], 1, 2, 3, 4), "bounds reads back what was set");
  [l setPosition: CGPointMake(5, 6)];
  PASS(peq([l position], 5, 6), "position reads back what was set");
  [l setAnchorPoint: CGPointMake(0.25, 0.75)];
  PASS(peq([l anchorPoint], 0.25, 0.75),
       "anchorPoint reads back what was set");
  [l setAnchorPointZ: 7];
  PASS(eq([l anchorPointZ], 7), "anchorPointZ reads back what was set");
  [l setZPosition: -5];
  PASS(eq([l zPosition], -5), "zPosition reads back what was set");
  [l setContentsScale: 2];
  PASS(eq([l contentsScale], 2), "contentsScale reads back what was set");
  [l setMasksToBounds: YES];
  PASS([l masksToBounds] == YES, "masksToBounds reads back what was set");
  [l setGeometryFlipped: YES];
  PASS([l isGeometryFlipped] == YES,
       "geometryFlipped reads back what was set");
  [l setHidden: YES];
  PASS([l isHidden] == YES, "hidden reads back what was set");

  [l setTransform: CATransform3DMakeScale(2, 3, 4)];
  CATransform3D t = [l transform];
  PASS(eq(t.m11, 2) && eq(t.m22, 3) && eq(t.m33, 4),
       "transform reads back what was set");
  [l setSublayerTransform: CATransform3DMakeTranslation(8, 9, 10)];
  CATransform3D s = [l sublayerTransform];
  PASS(eq(s.m41, 8) && eq(s.m42, 9) && eq(s.m43, 10),
       "sublayerTransform reads back what was set");

  /* setting the bounds must leave the position and the anchor point alone */
  CALayer *k = [CALayer layer];
  [k setPosition: CGPointMake(7, 9)];
  [k setAnchorPoint: CGPointMake(0.25, 0.75)];
  [k setBounds: CGRectMake(0, 0, 30, 40)];
  PASS(peq([k position], 7, 9), "setting the bounds does not move the layer");
  PASS(peq([k anchorPoint], 0.25, 0.75),
       "setting the bounds does not move the anchor point");

  /* an anchor point outside the unit square is accepted as given */
  CALayer *o = [CALayer layer];
  [o setAnchorPoint: CGPointMake(2, -1)];
  PASS(peq([o anchorPoint], 2, -1),
       "an anchor point outside the unit square is kept");

  CALayer *n = [CALayer layer];
  [n setBounds: CGRectMake(0, 0, -100, -50)];
  testHopeful = YES;
  PASS(req([n bounds], -100, -50, 100, 50),
       "bounds with a negative size are standardised");
  testHopeful = NO;
}

/* The frame is not stored.  It is the bounds size, placed so that the anchor
   point lands on the position, with the layer transform applied about that
   anchor point and the result taken as a bounding box. */
static void frame(void)
{
  testHopeful = YES;

  CALayer *l = [CALayer layer];
  [l setBounds: CGRectMake(0, 0, 100, 50)];
  [l setPosition: CGPointMake(200, 300)];
  PASS(req([l frame], 150, 275, 100, 50),
       "the frame of a centred layer straddles its position");

  [l setAnchorPoint: CGPointMake(0, 0)];
  PASS(req([l frame], 200, 300, 100, 50),
       "an anchor point at the corner puts the frame at the position");
  PASS(peq([l position], 200, 300),
       "moving the anchor point does not move the position");

  [l setAnchorPoint: CGPointMake(1, 1)];
  PASS(req([l frame], 100, 250, 100, 50),
       "an anchor point at the far corner puts the frame before the position");

  CALayer *o = [CALayer layer];
  [o setBounds: CGRectMake(11, 22, 100, 50)];
  [o setPosition: CGPointMake(200, 300)];
  PASS(req([o frame], 150, 275, 100, 50),
       "the bounds origin does not move the frame");

  CALayer *a = [CALayer layer];
  [a setBounds: CGRectMake(0, 0, 100, 50)];
  [a setPosition: CGPointMake(0, 0)];
  [a setAnchorPoint: CGPointMake(2, -1)];
  PASS(req([a frame], -200, 50, 100, 50),
       "an anchor point outside the unit square still places the frame");

  CALayer *z = [CALayer layer];
  [z setPosition: CGPointMake(10, 20)];
  PASS(req([z frame], 10, 20, 0, 0),
       "a layer with no size has an empty frame at its position");

  /* the frame is unaffected by the properties that do not place the layer */
  CALayer *u = [CALayer layer];
  [u setBounds: CGRectMake(0, 0, 100, 50)];
  [u setPosition: CGPointMake(200, 300)];
  [u setZPosition: 17];
  [u setAnchorPointZ: 25];
  [u setGeometryFlipped: YES];
  [u setContentsScale: 2];
  PASS(req([u frame], 150, 275, 100, 50),
       "the depth and scale properties do not move the frame");

  testHopeful = NO;
}

static void setFrame(void)
{
  testHopeful = YES;

  CALayer *l = [CALayer layer];
  [l setFrame: CGRectMake(10, 20, 100, 50)];
  PASS(req([l bounds], 0, 0, 100, 50),
       "setting the frame sizes the bounds");
  PASS(peq([l position], 60, 45),
       "setting the frame moves the position to the anchor point");
  PASS(peq([l anchorPoint], 0.5, 0.5),
       "setting the frame does not move the anchor point");
  PASS(req([l frame], 10, 20, 100, 50), "the frame reads back what was set");

  CALayer *a = [CALayer layer];
  [a setAnchorPoint: CGPointMake(0, 0)];
  [a setFrame: CGRectMake(10, 20, 100, 50)];
  PASS(peq([a position], 10, 20),
       "with the anchor point at the corner the position is the frame origin");

  CALayer *c = [CALayer layer];
  [c setAnchorPoint: CGPointMake(1, 1)];
  [c setFrame: CGRectMake(10, 20, 100, 50)];
  PASS(peq([c position], 110, 70),
       "with the anchor point at the far corner the position is the far edge");

  CALayer *o = [CALayer layer];
  [o setBounds: CGRectMake(11, 22, 5, 5)];
  [o setFrame: CGRectMake(10, 20, 100, 50)];
  PASS(req([o bounds], 11, 22, 100, 50),
       "setting the frame keeps the bounds origin");

  CALayer *n = [CALayer layer];
  [n setFrame: CGRectMake(0, 0, -100, -50)];
  PASS(req([n bounds], 0, 0, 100, 50),
       "a frame with a negative size is standardised into the bounds");
  PASS(peq([n position], -50, -25),
       "a frame with a negative size still places the position");

  CALayer *z = [CALayer layer];
  [z setFrame: CGRectMake(10, 20, 0, 0)];
  PASS(req([z bounds], 0, 0, 0, 0), "an empty frame gives empty bounds");
  PASS(peq([z position], 10, 20),
       "an empty frame puts the position at its origin");

  testHopeful = NO;
}

static void frameUnderTransform(void)
{
  testHopeful = YES;

  CALayer *s = [CALayer layer];
  [s setBounds: CGRectMake(0, 0, 100, 50)];
  [s setPosition: CGPointMake(200, 300)];
  [s setTransform: CATransform3DMakeScale(2, 4, 1)];
  PASS(req([s frame], 100, 200, 200, 200),
       "a scale grows the frame about the anchor point");

  CALayer *t = [CALayer layer];
  [t setBounds: CGRectMake(0, 0, 100, 50)];
  [t setPosition: CGPointMake(200, 300)];
  [t setTransform: CATransform3DMakeTranslation(10, 20, 0)];
  PASS(req([t frame], 160, 295, 100, 50),
       "a translation shifts the frame");

  CALayer *r = [CALayer layer];
  [r setBounds: CGRectMake(0, 0, 100, 100)];
  [r setPosition: CGPointMake(0, 0)];
  [r setTransform: CATransform3DMakeRotation(M_PI / 4, 0, 0, 1)];
  PASS(req([r frame], -50 * M_SQRT2, -50 * M_SQRT2,
           100 * M_SQRT2, 100 * M_SQRT2),
       "a rotation gives the frame the bounding box of the turned bounds");

  CALayer *sf = [CALayer layer];
  [sf setTransform: CATransform3DMakeScale(2, 4, 1)];
  [sf setFrame: CGRectMake(10, 20, 100, 50)];
  PASS(req([sf bounds], 0, 0, 50, 12.5),
       "setting the frame under a scale shrinks the bounds to match");
  PASS(peq([sf position], 60, 45),
       "setting the frame under a scale places the position");
  PASS(req([sf frame], 10, 20, 100, 50),
       "the frame set under a scale reads back unchanged");

  CALayer *tf = [CALayer layer];
  [tf setTransform: CATransform3DMakeTranslation(10, 20, 0)];
  [tf setFrame: CGRectMake(10, 20, 100, 50)];
  PASS(req([tf bounds], 0, 0, 100, 50),
       "setting the frame under a translation leaves the bounds size alone");
  PASS(peq([tf position], 50, 25),
       "setting the frame under a translation takes the shift back out");

  testHopeful = NO;
}

static void tree(void)
{
  CALayer *p = [CALayer layer];
  CALayer *a = [CALayer layer];
  CALayer *b = [CALayer layer];
  CALayer *c = [CALayer layer];

  [p addSublayer: a];
  PASS([[p sublayers] count] == 1, "adding a sublayer grows the sublayers");
  PASS([a superlayer] == p, "an added sublayer points back at its superlayer");

  [p addSublayer: b];
  [p insertSublayer: c atIndex: 1];
  PASS([[p sublayers] objectAtIndex: 0] == a
       && [[p sublayers] objectAtIndex: 1] == c
       && [[p sublayers] objectAtIndex: 2] == b,
       "a sublayer is inserted at the index asked for");

  [c removeFromSuperlayer];
  PASS([[p sublayers] count] == 2, "removing a sublayer shrinks the sublayers");
  PASS([c superlayer] == nil, "a removed sublayer has no superlayer");

  [p insertSublayer: c below: a];
  PASS([[p sublayers] objectAtIndex: 0] == c,
       "a sublayer inserted below a sibling takes its place");
  [c removeFromSuperlayer];
  [p insertSublayer: c above: a];
  PASS([[p sublayers] objectAtIndex: 1] == c,
       "a sublayer inserted above a sibling follows it");

  CALayer *q = [CALayer layer];
  [q addSublayer: a];
  testHopeful = YES;
  PASS([[p sublayers] count] == 2,
       "adding a sublayer to another layer removes it from the first");
  testHopeful = NO;
  PASS([a superlayer] == q, "a re-parented sublayer points at its new parent");
}

static void kvc(void)
{
  CALayer *l = [CALayer layer];
  [l setBounds: CGRectMake(0, 0, 100, 50)];
  [l setPosition: CGPointMake(200, 300)];

  PASS([l valueForKey: @"bounds"] != nil,
       "bounds is readable through key value coding");
  PASS([l valueForKey: @"position"] != nil,
       "position is readable through key value coding");

  [l setValue: [NSNumber numberWithDouble: 9] forKey: @"zPosition"];
  PASS(eq([l zPosition], 9), "zPosition is writable through key value coding");
}

static void classDefaults(void)
{
  PASS([CALayer defaultValueForKey: @"anchorPoint"] != nil,
       "the class supplies a default anchor point");
  PASS([CALayer defaultValueForKey: @"bounds"] == nil,
       "the class supplies no default bounds");
  PASS([CALayer defaultValueForKey: @"position"] == nil,
       "the class supplies no default position");
  PASS([CALayer defaultValueForKey: @"frame"] == nil,
       "the class supplies no default frame");

  id cs = [CALayer defaultValueForKey: @"contentsScale"];
  testHopeful = YES;
  PASS(cs != nil && eq([cs doubleValue], 1),
       "the class default contents scale is one");
  testHopeful = NO;
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("CALayer geometry")

  defaults();
  roundTrips();
  frame();
  setFrame();
  frameUnderTransform();
  tree();
  kvc();
  classDefaults();

  END_SET("CALayer geometry")

  [pool release];
  return 0;
}
