/* Where the contents of a layer land inside its bounds, for each gravity.
   The expected rectangles were measured against Apple QuartzCore with bounds
   80x60 and a contents image 20x10. */
#import <Foundation/Foundation.h>
#include "Testing.h"

#import <QuartzCore/QuartzCore.h>

/* Declared here rather than imported: the header is private to the
   framework and is not installed. */
CGRect CAGravityDestinationRect(NSString *gravity, CGRect bounds,
                                CGSize contentsSize);

static BOOL eq(CGFloat a, CGFloat b)
{
  CGFloat d = a - b;
  if (d < 0) d = -d;
  return d < 1e-4;
}

static BOOL is(NSString *gravity, CGFloat x, CGFloat y, CGFloat w, CGFloat h)
{
  CGRect r = CAGravityDestinationRect(gravity, CGRectMake(0, 0, 80, 60),
                                      CGSizeMake(20, 10));

  return eq(r.origin.x, x) && eq(r.origin.y, y)
      && eq(r.size.width, w) && eq(r.size.height, h);
}

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("where the contents go")

  PASS(is(kCAGravityResize, 0, 0, 80, 60),
       "resize fills the bounds");
  PASS(is(kCAGravityResizeAspect, 0, 10, 80, 40),
       "resizeAspect fits inside and centres what is left over");
  PASS(is(kCAGravityResizeAspectFill, -20, 0, 120, 60),
       "resizeAspectFill covers the bounds and overflows");
  PASS(is(kCAGravityCenter, 30, 25, 20, 10),
       "center places the contents unscaled in the middle");
  PASS(is(kCAGravityTop, 30, 50, 20, 10), "top puts them against the top");
  PASS(is(kCAGravityBottom, 30, 0, 20, 10), "bottom against the bottom");
  PASS(is(kCAGravityLeft, 0, 25, 20, 10), "left against the left");
  PASS(is(kCAGravityRight, 60, 25, 20, 10), "right against the right");
  PASS(is(kCAGravityTopLeft, 0, 50, 20, 10), "topLeft into that corner");
  PASS(is(kCAGravityTopRight, 60, 50, 20, 10), "topRight into that one");
  PASS(is(kCAGravityBottomLeft, 0, 0, 20, 10), "bottomLeft into that one");
  PASS(is(kCAGravityBottomRight, 60, 0, 20, 10),
       "and bottomRight into the last");

  PASS(is(@"not a gravity", 30, 25, 20, 10),
       "a name it does not know is treated as center");
  PASS(is(nil, 30, 25, 20, 10), "and so is no name at all");

  CGRect empty = CAGravityDestinationRect(kCAGravityResize,
                                          CGRectMake(0, 0, 80, 60),
                                          CGSizeMake(0, 10));
  PASS(eq(empty.size.width, 0) && eq(empty.size.height, 0),
       "contents with no width occupy nothing");

  END_SET("where the contents go")

  [pool release];
  return 0;
}
