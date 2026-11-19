/* -visibleRect, -scrollPoint: and -scrollRectToVisible:, which Apple declares
   on CALayer rather than on CAScrollLayer.  Every value here was measured
   against Apple QuartzCore.

   The scroll layer has bounds 100x80 and holds a layer 500x400, so most of
   that layer is out of view and scrolling moves the scroll layer's bounds
   origin under it. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/CALayer.h>
#import <QuartzCore/CAScrollLayer.h>

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

static void withNoScrollLayer(void)
{
  CALayer *l = [CALayer layer];
  [l setBounds: CGRectMake(0, 0, 100, 80)];

  PASS(req([l visibleRect], 0, 0, 100, 80),
       "a layer with nothing to scroll it is visible throughout");
  [l scrollPoint: CGPointMake(30, 40)];
  PASS(req([l bounds], 0, 0, 100, 80),
       "and scrolling it to a point moves nothing");
  [l scrollRectToVisible: CGRectMake(200, 200, 10, 10)];
  PASS(req([l bounds], 0, 0, 100, 80),
       "and neither does scrolling a rectangle into view");
}

static void insideAScrollLayer(void)
{
  CAScrollLayer *scroll = [CAScrollLayer layer];
  CALayer *content = [CALayer layer];

  [scroll setBounds: CGRectMake(0, 0, 100, 80)];
  [content setFrame: CGRectMake(0, 0, 500, 400)];
  [scroll addSublayer: content];

  PASS(req([scroll visibleRect], 0, 0, 100, 80),
       "a scroll layer is visible throughout its own bounds");
  PASS(req([content visibleRect], 0, 0, 100, 80),
       "and shows only that much of a layer larger than itself");

  [content scrollPoint: CGPointMake(50, 60)];
  PASS(req([scroll bounds], 50, 60, 100, 80),
       "scrolling to a point moves the scroll layer bounds origin there");
  PASS(req([content visibleRect], 50, 60, 100, 80),
       "which is the part of the layer now in view");

  [scroll setBounds: CGRectMake(0, 0, 100, 80)];
  [scroll scrollPoint: CGPointMake(50, 60)];
  PASS(req([scroll bounds], 50, 60, 100, 80),
       "a scroll layer scrolls itself the same way");
}

static void rectangles(void)
{
  CAScrollLayer *scroll = [CAScrollLayer layer];
  CALayer *content = [CALayer layer];

  [content setFrame: CGRectMake(0, 0, 500, 400)];
  [scroll addSublayer: content];

  [scroll setBounds: CGRectMake(0, 0, 100, 80)];
  [content scrollRectToVisible: CGRectMake(200, 150, 20, 10)];
  PASS(req([scroll bounds], 120, 80, 100, 80),
       "a rectangle out of view is brought in by the least amount");

  [scroll setBounds: CGRectMake(0, 0, 100, 80)];
  [content scrollRectToVisible: CGRectMake(10, 10, 20, 10)];
  PASS(req([scroll bounds], 0, 0, 100, 80),
       "one already in view moves nothing");

  [scroll setBounds: CGRectMake(0, 0, 100, 80)];
  [content scrollRectToVisible: CGRectMake(200, 150, 400, 400)];
  PASS(req([scroll bounds], 200, 150, 100, 80),
       "and one too big to fit scrolls to its own origin");
}

static void deeperDown(void)
{
  CAScrollLayer *scroll = [CAScrollLayer layer];
  CALayer *content = [CALayer layer];
  CALayer *deep = [CALayer layer];

  [scroll setBounds: CGRectMake(0, 0, 100, 80)];
  [content setFrame: CGRectMake(0, 0, 500, 400)];
  [scroll addSublayer: content];
  [deep setFrame: CGRectMake(30, 40, 20, 20)];
  [content addSublayer: deep];

  PASS(req([deep visibleRect], 0, 0, 20, 20),
       "a small layer well inside the visible area is visible throughout");

  [deep scrollPoint: CGPointMake(5, 5)];
  PASS(req([scroll bounds], 35, 45, 100, 80),
       "a point is taken from the layer that was asked, not from the "
       "scroll layer");
  PASS(req([deep visibleRect], 5, 5, 15, 15),
       "which leaves only part of that layer in view");
}

static void scrollMode(void)
{
  CAScrollLayer *scroll = [CAScrollLayer layer];
  CALayer *content = [CALayer layer];

  [content setFrame: CGRectMake(0, 0, 500, 400)];
  [scroll addSublayer: content];

  [scroll setBounds: CGRectMake(0, 0, 100, 80)];
  [scroll setScrollMode: kCAScrollHorizontally];
  [content scrollPoint: CGPointMake(50, 60)];
  PASS(req([scroll bounds], 50, 0, 100, 80),
       "a scroll layer that only scrolls across ignores the vertical part");

  [scroll setBounds: CGRectMake(0, 0, 100, 80)];
  [scroll setScrollMode: kCAScrollNone];
  [content scrollPoint: CGPointMake(50, 60)];
  PASS(req([scroll bounds], 0, 0, 100, 80),
       "and one that does not scroll at all ignores both");
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("what a layer shows and how it is scrolled")

  withNoScrollLayer();
  insideAScrollLayer();
  rectangles();
  deeperDown();
  scrollMode();

  END_SET("what a layer shows and how it is scrolled")

  [pool release];
  return 0;
}
