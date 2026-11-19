/* A layer resized because its superlayer was.  Every frame expected here was
   measured against Apple QuartzCore.

   The superlayer goes from 100x100 to 200x300 and the sublayer starts at
   frame (10, 20, 50, 40), so the horizontal parts are 10 / 50 / 40 and the
   vertical parts are 20 / 40 / 40.  No two of them are the same size, which
   is what shows that the change is shared out by which parts give way and
   not by how big they are: a leading margin of 10 and an extent of 50 take
   66 and 34 of a change of 100. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/QuartzCore.h>

static BOOL eq(CGFloat a, CGFloat b)
{
  CGFloat d = a - b;
  if (d < 0) d = -d;
  return d < 1e-4;
}

static BOOL req(CGRect r, CGFloat x, CGFloat y, CGFloat w, CGFloat h)
{
  return eq(r.origin.x, x) && eq(r.origin.y, y)
      && eq(r.size.width, w) && eq(r.size.height, h);
}

/* Build the tree, change the superlayer bounds once, answer the frame. */
static CGRect resized(unsigned mask, CGFloat newWidth, CGFloat newHeight)
{
  CALayer *sup = [CALayer layer];
  CALayer *sub = [CALayer layer];

  [sup setBounds: CGRectMake(0, 0, 100, 100)];
  [sub setFrame: CGRectMake(10, 20, 50, 40)];
  [sub setAutoresizingMask: mask];
  [sup addSublayer: sub];
  [sup setBounds: CGRectMake(0, 0, newWidth, newHeight)];
  return [sub frame];
}

static void constants(void)
{
  PASS(kCALayerNotSizable == 0, "a layer that does not give way is zero");
  PASS(kCALayerMinXMargin == 1, "the leading horizontal margin is bit zero");
  PASS(kCALayerWidthSizable == 2, "the width is bit one");
  PASS(kCALayerMaxXMargin == 4, "the trailing horizontal margin is bit two");
  PASS(kCALayerMinYMargin == 8, "the leading vertical margin is bit three");
  PASS(kCALayerHeightSizable == 16, "the height is bit four");
  PASS(kCALayerMaxYMargin == 32, "the trailing vertical margin is bit five");
}

static void property(void)
{
  CALayer *l = [CALayer layer];

  PASS([l autoresizingMask] == kCALayerNotSizable,
       "a new layer does not give way at all");
  [l setAutoresizingMask: kCALayerWidthSizable | kCALayerHeightSizable];
  PASS([l autoresizingMask] == (kCALayerWidthSizable | kCALayerHeightSizable),
       "the mask reads back what it was given");
  [l setAutoresizingMask: 255];
  PASS([l autoresizingMask] == 255, "including bits with no meaning");
  [l setAutoresizingMask: 0];
  PASS([l autoresizingMask] == 0, "and it can be put back to zero");
  PASS([CALayer defaultValueForKey: @"autoresizingMask"] == nil,
       "the class has no default mask");
}

static void onePartAtATime(void)
{
  PASS(req(resized(kCALayerNotSizable, 200, 300), 10, 20, 50, 40),
       "a layer that gives way nowhere does not move");
  PASS(req(resized(kCALayerMinXMargin, 200, 300), 110, 20, 50, 40),
       "a leading horizontal margin alone takes the whole change");
  PASS(req(resized(kCALayerWidthSizable, 200, 300), 10, 20, 150, 40),
       "a width alone takes the whole change");
  PASS(req(resized(kCALayerMaxXMargin, 200, 300), 10, 20, 50, 40),
       "a trailing horizontal margin alone leaves the frame where it is");
  PASS(req(resized(kCALayerMinYMargin, 200, 300), 10, 220, 50, 40),
       "a leading vertical margin alone takes the whole change");
  PASS(req(resized(kCALayerHeightSizable, 200, 300), 10, 20, 50, 240),
       "a height alone takes the whole change");
  PASS(req(resized(kCALayerMaxYMargin, 200, 300), 10, 20, 50, 40),
       "a trailing vertical margin alone leaves the frame where it is");
}

static void sharedOut(void)
{
  PASS(req(resized(kCALayerMinXMargin | kCALayerWidthSizable, 200, 300),
           76, 20, 84, 40),
       "a leading margin and a width take two thirds and one third");
  PASS(req(resized(kCALayerWidthSizable | kCALayerMaxXMargin, 200, 300),
           10, 20, 84, 40),
       "a width and a trailing margin take one third and two thirds");
  PASS(req(resized(kCALayerMinXMargin | kCALayerMaxXMargin, 200, 300),
           60, 20, 50, 40),
       "two margins with a fixed width take half each");
  PASS(req(resized(kCALayerMinXMargin | kCALayerWidthSizable
                   | kCALayerMaxXMargin, 200, 300), 43, 20, 84, 40),
       "all three take a third each");

  PASS(req(resized(kCALayerMinYMargin | kCALayerHeightSizable, 200, 300),
           10, 153, 50, 107),
       "the vertical parts are shared out the same way");
  PASS(req(resized(kCALayerMinYMargin | kCALayerMaxYMargin, 200, 300),
           10, 120, 50, 40),
       "two vertical margins with a fixed height take half each");
  PASS(req(resized(kCALayerMinYMargin | kCALayerHeightSizable
                   | kCALayerMaxYMargin, 200, 300), 10, 86, 50, 108),
       "and all three vertical parts take a third each");

  PASS(req(resized(kCALayerWidthSizable | kCALayerHeightSizable, 200, 300),
           10, 20, 150, 240),
       "the two axes are worked out independently");
  PASS(req(resized(63, 200, 300), 43, 86, 84, 108),
       "a layer that gives way everywhere moves on both axes at once");
}

static void otherChanges(void)
{
  PASS(req(resized(kCALayerMinXMargin | kCALayerWidthSizable, 400, 100),
           210, 20, 150, 40),
       "a change of 300 divides exactly, two thirds and one third");
  PASS(req(resized(kCALayerMinXMargin | kCALayerWidthSizable, 110, 100),
           16, 20, 54, 40),
       "a change of 10 puts the margin on the point below");
  PASS(req(resized(kCALayerMinXMargin | kCALayerWidthSizable, 50, 25),
           -24, 20, 34, 40),
       "a superlayer that shrinks pulls the layer off its leading edge");
  PASS(req(resized(kCALayerWidthSizable | kCALayerHeightSizable, 50, 25),
           10, -15, 0, 35),
       "and can leave it with no width at all");
}

static void whenItHappens(void)
{
  CALayer *sup = [CALayer layer];
  CALayer *sub = [CALayer layer];
  [sup setBounds: CGRectMake(0, 0, 100, 100)];
  [sub setFrame: CGRectMake(10, 20, 50, 40)];
  [sub setAutoresizingMask: kCALayerWidthSizable | kCALayerHeightSizable];
  [sup addSublayer: sub];
  [sup setBounds: CGRectMake(30, 40, 100, 100)];
  PASS(req([sub frame], 10, 20, 50, 40),
       "moving the bounds without resizing them moves nothing");

  CALayer *fsup = [CALayer layer];
  CALayer *fsub = [CALayer layer];
  [fsup setBounds: CGRectMake(0, 0, 100, 100)];
  [fsub setFrame: CGRectMake(10, 20, 50, 40)];
  [fsub setAutoresizingMask: kCALayerWidthSizable | kCALayerHeightSizable];
  [fsup addSublayer: fsub];
  [fsup setFrame: CGRectMake(0, 0, 200, 300)];
  PASS(req([fsub frame], 10, 20, 150, 240),
       "setting the superlayer frame resizes the sublayer too");

  CALayer *lsup = [CALayer layer];
  CALayer *lsub = [CALayer layer];
  [lsup setBounds: CGRectMake(0, 0, 100, 100)];
  [lsub setFrame: CGRectMake(10, 20, 50, 40)];
  [lsup addSublayer: lsub];
  [lsup setBounds: CGRectMake(0, 0, 200, 300)];
  [lsub setAutoresizingMask: kCALayerWidthSizable | kCALayerHeightSizable];
  PASS(req([lsub frame], 10, 20, 50, 40),
       "a mask given after the change does not act on it");

  CALayer *asup = [CALayer layer];
  CALayer *asub = [CALayer layer];
  [asup setBounds: CGRectMake(0, 0, 200, 300)];
  [asub setFrame: CGRectMake(10, 20, 50, 40)];
  [asub setAutoresizingMask: kCALayerWidthSizable | kCALayerHeightSizable];
  [asup addSublayer: asub];
  PASS(req([asub frame], 10, 20, 50, 40),
       "and a layer added afterwards keeps the frame it was given");
}

static void sentDirectly(void)
{
  CALayer *sup = [CALayer layer];
  CALayer *sub = [CALayer layer];
  [sup setBounds: CGRectMake(0, 0, 200, 300)];
  [sub setFrame: CGRectMake(10, 20, 50, 40)];
  [sub setAutoresizingMask: kCALayerMinXMargin | kCALayerWidthSizable];
  [sup addSublayer: sub];
  [sub resizeWithOldSuperlayerSize: CGSizeMake(100, 100)];
  PASS(req([sub frame], 76, 20, 84, 40),
       "the layer can be told its superlayer size changed");

  CALayer *ssup = [CALayer layer];
  CALayer *ssub = [CALayer layer];
  [ssup setBounds: CGRectMake(0, 0, 200, 300)];
  [ssub setFrame: CGRectMake(10, 20, 50, 40)];
  [ssub setAutoresizingMask: kCALayerWidthSizable | kCALayerHeightSizable];
  [ssup addSublayer: ssub];
  [ssup resizeSublayersWithOldSize: CGSizeMake(100, 100)];
  PASS(req([ssub frame], 10, 20, 150, 240),
       "or the superlayer can pass it on to all of them");

  CALayer *nsup = [CALayer layer];
  CALayer *nsub = [CALayer layer];
  [nsup setBounds: CGRectMake(0, 0, 100, 100)];
  [nsub setFrame: CGRectMake(10, 20, 50, 40)];
  [nsub setAutoresizingMask: kCALayerWidthSizable];
  [nsup addSublayer: nsub];
  [nsup resizeSublayersWithOldSize: CGSizeMake(100, 100)];
  PASS(req([nsub frame], 10, 20, 50, 40),
       "a size that did not change moves nothing");
}

static void downTheTree(void)
{
  CALayer *sup = [CALayer layer];
  CALayer *mid = [CALayer layer];
  CALayer *leaf = [CALayer layer];

  [sup setBounds: CGRectMake(0, 0, 100, 100)];
  [mid setFrame: CGRectMake(0, 0, 100, 100)];
  [mid setAutoresizingMask: kCALayerWidthSizable | kCALayerHeightSizable];
  [sup addSublayer: mid];
  [leaf setFrame: CGRectMake(10, 20, 50, 40)];
  [leaf setAutoresizingMask: kCALayerWidthSizable | kCALayerHeightSizable];
  [mid addSublayer: leaf];

  [sup setBounds: CGRectMake(0, 0, 200, 300)];
  PASS(req([mid frame], 0, 0, 200, 300), "the layer between the two resizes");
  PASS(req([leaf frame], 10, 20, 150, 240),
       "and carries the change on down to its own sublayers");
}

static void archiving(void)
{
  CALayer *l = [CALayer layer];

  PASS([l shouldArchiveValueForKey: @"autoresizingMask"] == NO,
       "a new layer does not archive a mask nobody set");
  [l setAutoresizingMask: kCALayerWidthSizable];
  PASS([l shouldArchiveValueForKey: @"autoresizingMask"] == YES,
       "and does archive one it was given");
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("autoresizing")

  constants();
  property();
  onePartAtATime();
  sharedOut();
  otherChanges();
  whenItHappens();
  sentDirectly();
  downTheTree();
  archiving();

  END_SET("autoresizing")

  [pool release];
  return 0;
}
