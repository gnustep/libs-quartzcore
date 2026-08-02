/* CAMediaTimingFunction control points for the named functions and a custom
   function.  Expected values checked against Apple QuartzCore. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>
#include <Foundation/NSGeometry.h>
#include <QuartzCore/CAMediaTimingFunction.h>
#include <math.h>

static BOOL cp(CAMediaTimingFunction *f, size_t i, float x, float y)
{
  float p[2];
  [f getControlPointAtIndex: i values: p];
  return fabsf(p[0] - x) < 1e-4 && fabsf(p[1] - y) < 1e-4;
}

int main(void)
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  CAMediaTimingFunction *f;

  START_SET("CAMediaTimingFunction")

  f = [CAMediaTimingFunction functionWithControlPoints: 0.1 : 1.0 : 1.0 : 0.2];
  PASS(cp(f, 0, 0, 0) && cp(f, 1, 0.1, 1.0) && cp(f, 2, 1.0, 0.2)
       && cp(f, 3, 1, 1),
       "a custom function keeps its control points and the (0,0)/(1,1) endpoints");

  f = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear];
  PASS(cp(f, 0, 0, 0) && cp(f, 1, 0, 0) && cp(f, 2, 1, 1) && cp(f, 3, 1, 1),
       "the linear function runs straight from (0,0) to (1,1)");

  f = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn];
  PASS(cp(f, 1, 0.42, 0) && cp(f, 2, 1, 1),
       "ease-in control points are (0.42,0) and (1,1)");

  f = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut];
  PASS(cp(f, 1, 0, 0) && cp(f, 2, 0.58, 1),
       "ease-out control points are (0,0) and (0.58,1)");

  f = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut];
  PASS(cp(f, 1, 0.42, 0) && cp(f, 2, 0.58, 1),
       "ease-in-ease-out control points are (0.42,0) and (0.58,1)");

  f = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionDefault];
  PASS(cp(f, 1, 0.25, 0.1) && cp(f, 2, 0.25, 1),
       "default control points are (0.25,0.1) and (0.25,1)");

  END_SET("CAMediaTimingFunction")

  [arp release];
  return 0;
}
