/* The CATransform3D <-> CGAffineTransform bridge: making a transform from an
   affine transform, testing whether a transform is affine, and getting the
   affine transform back.  Expected values checked against Apple QuartzCore. */
#include "Testing.h"

#include <QuartzCore/CATransform3D.h>
#include <math.h>

static BOOL eq(CGFloat a, CGFloat b)
{
  CGFloat d = a - b;
  if (d < 0) d = -d;
  return d < 1e-4;
}

int main(void)
{
  START_SET("CATransform3D affine bridge")

  /* Make a 3D transform from a 2D affine transform. */
  CGAffineTransform a = CGAffineTransformMake(2, 3, 4, 5, 6, 7);
  CATransform3D m = CATransform3DMakeAffineTransform(a);
  PASS(eq(m.m11, 2) && eq(m.m12, 3) && eq(m.m21, 4) && eq(m.m22, 5)
       && eq(m.m41, 6) && eq(m.m42, 7),
       "MakeAffineTransform places the affine components");
  PASS(eq(m.m13, 0) && eq(m.m14, 0) && eq(m.m23, 0) && eq(m.m24, 0)
       && eq(m.m31, 0) && eq(m.m32, 0) && eq(m.m34, 0) && eq(m.m43, 0)
       && eq(m.m33, 1) && eq(m.m44, 1),
       "MakeAffineTransform leaves the rest as the identity");

  /* IsAffine. */
  PASS(CATransform3DIsAffine(CATransform3DIdentity),
       "the identity is affine");
  PASS(CATransform3DIsAffine(m),
       "a transform built from an affine transform is affine");
  PASS(CATransform3DIsAffine(CATransform3DMakeRotation(1, 0, 0, 1)),
       "a rotation about z is affine");
  PASS(!CATransform3DIsAffine(CATransform3DMakeRotation(1, 1, 0, 0)),
       "a rotation about x is not affine");
  PASS(!CATransform3DIsAffine(CATransform3DMakeScale(1, 1, 2)),
       "a z scale is not affine");
  PASS(!CATransform3DIsAffine(CATransform3DMakeTranslation(0, 0, 5)),
       "a z translation is not affine");
  CATransform3D pers = CATransform3DIdentity;
  pers.m34 = -1.0/500;
  PASS(!CATransform3DIsAffine(pers), "a perspective transform is not affine");

  /* GetAffineTransform. */
  CGAffineTransform back = CATransform3DGetAffineTransform(m);
  PASS(eq(back.a, 2) && eq(back.b, 3) && eq(back.c, 4) && eq(back.d, 5)
       && eq(back.tx, 6) && eq(back.ty, 7),
       "GetAffineTransform returns the affine components");

  /* Round-trip. */
  CGAffineTransform rt = CATransform3DGetAffineTransform(
    CATransform3DMakeAffineTransform(a));
  PASS(eq(rt.a, a.a) && eq(rt.b, a.b) && eq(rt.c, a.c) && eq(rt.d, a.d)
       && eq(rt.tx, a.tx) && eq(rt.ty, a.ty),
       "an affine transform round-trips through a 3D transform");

  END_SET("CATransform3D affine bridge")

  return 0;
}
