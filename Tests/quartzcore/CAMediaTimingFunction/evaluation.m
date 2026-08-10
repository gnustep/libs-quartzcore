/* What a timing function evaluates to along its curve, and at the two ends
   of it.  Expected values checked against Apple QuartzCore.

   The slope of x(t) is zero at t=0 when the first control point sits on the
   y axis, and at t=1 when the second sits on the line x=1, which is where a
   solver that divides by that slope comes apart.  Linear has both, ease in
   has the second and ease out the first. */
#import <Foundation/Foundation.h>
#include "Testing.h"
#include <math.h>

#import <QuartzCore/CAMediaTimingFunction.h>

/* Private on Apple, and implemented here so both can be asked the same
   question. */
@interface CAMediaTimingFunction (Solve)
- (float) _solveForInput: (float)x;
@end

#define CLOSE(a, b) (fabs((double)(a) - (double)(b)) < 1e-4)

int main(void)
{
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  START_SET("the ends of the curve")

  NSArray *names = [NSArray arrayWithObjects:
    kCAMediaTimingFunctionLinear, kCAMediaTimingFunctionEaseIn,
    kCAMediaTimingFunctionEaseOut, kCAMediaTimingFunctionEaseInEaseOut,
    kCAMediaTimingFunctionDefault, nil];
  NSEnumerator *e = [names objectEnumerator];
  NSString *name;
  unsigned atZero = 0;
  unsigned atOne = 0;

  while ((name = [e nextObject]) != nil)
    {
      CAMediaTimingFunction *f = [CAMediaTimingFunction functionWithName: name];

      if (CLOSE([f _solveForInput: 0.0], 0.0))
        {
          atZero++;
        }
      if (CLOSE([f _solveForInput: 1.0], 1.0))
        {
          atOne++;
        }
    }

  PASS(atZero == 5, "every named function is 0 where the input is 0");
  PASS(atOne == 5, "every named function is 1 where the input is 1");

  END_SET("the ends of the curve")

  START_SET("a straight line")

  CAMediaTimingFunction *f = [CAMediaTimingFunction functionWithName:
                                kCAMediaTimingFunctionLinear];

  PASS(CLOSE([f _solveForInput: 0.25], 0.25), "linear is 0.25 at 0.25");
  PASS(CLOSE([f _solveForInput: 0.5], 0.5), "linear is 0.5 at 0.5");
  PASS(CLOSE([f _solveForInput: 0.75], 0.75), "linear is 0.75 at 0.75");

  END_SET("a straight line")

  START_SET("along the eased curves")

  CAMediaTimingFunction *in = [CAMediaTimingFunction functionWithName:
                                 kCAMediaTimingFunctionEaseIn];
  CAMediaTimingFunction *out = [CAMediaTimingFunction functionWithName:
                                  kCAMediaTimingFunctionEaseOut];
  CAMediaTimingFunction *both = [CAMediaTimingFunction functionWithName:
                                   kCAMediaTimingFunctionEaseInEaseOut];

  PASS(CLOSE([in _solveForInput: 0.25], 0.093465), "ease in at 0.25");
  PASS(CLOSE([in _solveForInput: 0.5], 0.315357), "ease in at 0.5");
  PASS(CLOSE([in _solveForInput: 0.75], 0.621861), "ease in at 0.75");

  PASS(CLOSE([out _solveForInput: 0.25], 0.378140), "ease out at 0.25");
  PASS(CLOSE([out _solveForInput: 0.5], 0.684643), "ease out at 0.5");
  PASS(CLOSE([out _solveForInput: 0.75], 0.906535), "ease out at 0.75");

  PASS(CLOSE([both _solveForInput: 0.25], 0.129162), "ease in ease out at 0.25");
  PASS(CLOSE([both _solveForInput: 0.5], 0.5), "ease in ease out at 0.5");
  PASS(CLOSE([both _solveForInput: 0.75], 0.870838), "ease in ease out at 0.75");

  END_SET("along the eased curves")

  START_SET("a curve given its control points")

  CAMediaTimingFunction *straight = [CAMediaTimingFunction
    functionWithControlPoints: 0.0: 0.0: 1.0: 1.0];
  CAMediaTimingFunction *steep = [CAMediaTimingFunction
    functionWithControlPoints: 0.5: 0.0: 0.5: 1.0];

  PASS(CLOSE([straight _solveForInput: 0.0], 0.0),
       "control points along the diagonal are 0 at 0");
  PASS(CLOSE([straight _solveForInput: 0.5], 0.5),
       "control points along the diagonal are 0.5 at 0.5");
  PASS(CLOSE([straight _solveForInput: 1.0], 1.0),
       "control points along the diagonal are 1 at 1");

  PASS(CLOSE([steep _solveForInput: 0.25], 0.105889),
       "a curve of 0.5,0,0.5,1 at 0.25");
  PASS(CLOSE([steep _solveForInput: 0.5], 0.5),
       "a curve of 0.5,0,0.5,1 at 0.5");
  PASS(CLOSE([steep _solveForInput: 0.75], 0.894111),
       "a curve of 0.5,0,0.5,1 at 0.75");

  END_SET("a curve given its control points")

  START_SET("outside the curve")

  CAMediaTimingFunction *line = [CAMediaTimingFunction functionWithName:
                                   kCAMediaTimingFunctionLinear];

  PASS(CLOSE([line _solveForInput: -0.5], 0.0),
       "an input below 0 is held at 0");
  PASS(CLOSE([line _solveForInput: 1.5], 1.0),
       "an input above 1 is held at 1");

  END_SET("outside the curve")

  [pool release];
  return 0;
}
