/* CATransform3D construction, composition, inversion and the identity and
   equality predicates.  Expected values checked against Apple QuartzCore. */
#include "Testing.h"

#include <QuartzCore/CATransform3D.h>
#include <math.h>

static BOOL eq(CGFloat a, CGFloat b)
{
  CGFloat d = a - b;
  if (d < 0) d = -d;
  return d < 1e-4;
}

static BOOL teq(CATransform3D t,
                CGFloat m11, CGFloat m12, CGFloat m13, CGFloat m14,
                CGFloat m21, CGFloat m22, CGFloat m23, CGFloat m24,
                CGFloat m31, CGFloat m32, CGFloat m33, CGFloat m34,
                CGFloat m41, CGFloat m42, CGFloat m43, CGFloat m44)
{
  return eq(t.m11, m11) && eq(t.m12, m12) && eq(t.m13, m13) && eq(t.m14, m14)
      && eq(t.m21, m21) && eq(t.m22, m22) && eq(t.m23, m23) && eq(t.m24, m24)
      && eq(t.m31, m31) && eq(t.m32, m32) && eq(t.m33, m33) && eq(t.m34, m34)
      && eq(t.m41, m41) && eq(t.m42, m42) && eq(t.m43, m43) && eq(t.m44, m44);
}

int main(void)
{
  START_SET("CATransform3D")

  CGFloat cs = cos(M_PI / 2);
  CGFloat sn = sin(M_PI / 2);

  PASS(teq(CATransform3DIdentity, 1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1),
       "the identity transform is the 4x4 identity");
  PASS(teq(CATransform3DMakeTranslation(2, 3, 4),
           1,0,0,0, 0,1,0,0, 0,0,1,0, 2,3,4,1),
       "translation goes in the bottom row");
  PASS(teq(CATransform3DMakeScale(2, 3, 4),
           2,0,0,0, 0,3,0,0, 0,0,4,0, 0,0,0,1),
       "scale goes on the diagonal");
  PASS(teq(CATransform3DMakeRotation(M_PI / 2, 0, 0, 1),
           cs,sn,0,0, -sn,cs,0,0, 0,0,1,0, 0,0,0,1),
       "rotation about z fills the x/y block");
  PASS(teq(CATransform3DMakeRotation(M_PI / 2, 1, 0, 0),
           1,0,0,0, 0,cs,sn,0, 0,-sn,cs,0, 0,0,0,1),
       "rotation about x fills the y/z block");

  CATransform3D tr = CATransform3DMakeTranslation(10, 0, 0);
  CATransform3D sc = CATransform3DMakeScale(2, 2, 2);

  PASS(teq(CATransform3DConcat(tr, sc),
           2,0,0,0, 0,2,0,0, 0,0,2,0, 20,0,0,1),
       "Concat(translate,scale) applies the translation first");
  PASS(teq(CATransform3DConcat(sc, tr),
           2,0,0,0, 0,2,0,0, 0,0,2,0, 10,0,0,1),
       "Concat(scale,translate) leaves the translation unscaled");
  PASS(teq(CATransform3DTranslate(sc, 10, 0, 0),
           2,0,0,0, 0,2,0,0, 0,0,2,0, 20,0,0,1),
       "Translate builds on the transform with the translation first");
  PASS(teq(CATransform3DScale(tr, 2, 2, 2),
           2,0,0,0, 0,2,0,0, 0,0,2,0, 10,0,0,1),
       "Scale builds on the transform with the scale first");
  testHopeful = YES;
  PASS(teq(CATransform3DInvert(sc),
           0.5,0,0,0, 0,0.5,0,0, 0,0,0.5,0, 0,0,0,1),
       "inverting a scale reciprocates the diagonal");
  testHopeful = NO;

  PASS(CATransform3DIsIdentity(CATransform3DIdentity),
       "the identity transform reports itself as the identity");
  PASS(!CATransform3DIsIdentity(sc),
       "a scale is not the identity");
  PASS(CATransform3DEqualToTransform(sc, CATransform3DMakeScale(2, 2, 2)),
       "equal transforms compare equal");
  PASS(!CATransform3DEqualToTransform(sc, tr),
       "different transforms compare unequal");

  END_SET("CATransform3D")
  return 0;
}
