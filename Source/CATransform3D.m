/* CATransform3D.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vučica <ivan@vucica.net>
   Date: June 2012
   
   This file is part of QuartzCore.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the
   Free Software Foundation, 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

#import "QuartzCore/CATransform3D.h"

const CATransform3D CATransform3DIdentity = {
  1, 0, 0, 0,
  0, 1, 0, 0,
  0, 0, 1, 0,
  0, 0, 0, 1
};

BOOL CATransform3DIsIdentity(CATransform3D t)
{
  return (t.m11==1.0 && t.m12==0.0 && t.m13==0.0 && t.m14==0.0 &&
          t.m21==0.0 && t.m22==1.0 && t.m23==0.0 && t.m24==0.0 &&
          t.m31==0.0 && t.m32==0.0 && t.m33==1.0 && t.m34==0.0 &&
          t.m41==0.0 && t.m42==0.0 && t.m43==0.0 && t.m44==1.0);
}
BOOL CATransform3DEqualToTransform(CATransform3D a, CATransform3D b)
{
  return 
    (a.m11 == b.m11 && a.m12 == b.m12 && a.m13 == b.m13 && a.m14 == b.m14 &&
     a.m21 == b.m21 && a.m22 == b.m22 && a.m23 == b.m23 && a.m24 == b.m24 &&
     a.m31 == b.m31 && a.m32 == b.m32 && a.m33 == b.m33 && a.m34 == b.m34 &&
     a.m41 == b.m41 && a.m42 == b.m42 && a.m43 == b.m43 && a.m44 == b.m44);
}

CATransform3D CATransform3DMakeTranslation(CGFloat tx, CGFloat ty, CGFloat tz)
{
  return (CATransform3D){
    1,  0,  0,  0,
    0,  1,  0,  0,
    0,  0,  1,  0,
    tx, ty, tz, 1};
}

CATransform3D CATransform3DMakeScale(CGFloat sx, CGFloat sy, CGFloat sz)
{
  return (CATransform3D){
    sx, 0,  0,  0,
    0,  sy, 0,  0,
    0,  0,  sz, 0,
    0, 0, 0, 1};
}

CATransform3D CATransform3DMakeRotation(CGFloat radians, CGFloat x, CGFloat y, CGFloat z)
{
  /* Zero length vector returns identity */
  if (x == 0.0 && y == 0.0 && z == 0.0)
    return CATransform3DIdentity;


  /* Precalculate sin and cos */
  float s = sin(radians);
  float c = cos(radians);

  /* Normalize vector */
  float len = sqrt(x*x + y*y + z*z);
  x /= len; y /= len; z /= len;

  /* Fill the return value */
  CATransform3D returnValue;

  returnValue.m11 = c + (1-c) * x*x;
  returnValue.m12 = (1-c) * x*y + s*z;
  returnValue.m13 = (1-c) * x*z - s*y;
  returnValue.m14 = 0;

  returnValue.m21 = (1-c) * y*x - s*z;
  returnValue.m22 = c + (1-c) * y*y;
  returnValue.m23 = (1-c) * y*z + s*x;
  returnValue.m24 = 0;

  returnValue.m31 = (1-c) * z*x + s*y;
  returnValue.m32 = (1-c) * y*z - s*x;
  returnValue.m33 = c + (1-c) * z*z;
  returnValue.m34 = 0;

  returnValue.m41 = 0;
  returnValue.m42 = 0;
  returnValue.m43 = 0;
  returnValue.m44 = 1;
 
  return returnValue;
}

/* idea for a GS extension: rotation matrices for rotation around x, y and z.
   somewhat simpler.
   - x: m22=c, m23=s,  m32=-s, m33=c
   - y: m11=c, m13=-s, m31=c,  m33=c
   - z: m11=c, m12=s,  m21=-s, m22=c
 */

CATransform3D CATransform3DTranslate(CATransform3D t, CGFloat tx, CGFloat ty, CGFloat tz)
{
  return CATransform3DConcat (CATransform3DMakeTranslation(tx, ty, tz), t);
}

CATransform3D CATransform3DScale(CATransform3D t, CGFloat sx, CGFloat sy, CGFloat sz)
{
  return CATransform3DConcat (CATransform3DMakeScale(sx, sy, sz), t);
}

CATransform3D CATransform3DRotate(CATransform3D t, CGFloat radians, CGFloat x, CGFloat y, CGFloat z)
{
  return CATransform3DConcat (CATransform3DMakeRotation(radians, x, y, z), t);
}

CATransform3D CATransform3DConcat(CATransform3D b, CATransform3D a)
{
  /* multiplication */
  CATransform3D result;

  result.m11  = (a.m11*b.m11)+(a.m21*b.m12)+(a.m31*b.m13)+(a.m41*b.m14);
  result.m12  = (a.m12*b.m11)+(a.m22*b.m12)+(a.m32*b.m13)+(a.m42*b.m14);
  result.m13  = (a.m13*b.m11)+(a.m23*b.m12)+(a.m33*b.m13)+(a.m43*b.m14);
  result.m14  = (a.m14*b.m11)+(a.m24*b.m12)+(a.m34*b.m13)+(a.m44*b.m14);

  result.m21  = (a.m11*b.m21)+(a.m21*b.m22)+(a.m31*b.m23)+(a.m41*b.m24);
  result.m22  = (a.m12*b.m21)+(a.m22*b.m22)+(a.m32*b.m23)+(a.m42*b.m24);
  result.m23  = (a.m13*b.m21)+(a.m23*b.m22)+(a.m33*b.m23)+(a.m43*b.m24);
  result.m24  = (a.m14*b.m21)+(a.m24*b.m22)+(a.m34*b.m23)+(a.m44*b.m24);

  result.m31  = (a.m11*b.m31)+(a.m21*b.m32)+(a.m31*b.m33)+(a.m41*b.m34);
  result.m32  = (a.m12*b.m31)+(a.m22*b.m32)+(a.m32*b.m33)+(a.m42*b.m34);
  result.m33 = (a.m13*b.m31)+(a.m23*b.m32)+(a.m33*b.m33)+(a.m43*b.m34);
  result.m34 = (a.m14*b.m31)+(a.m24*b.m32)+(a.m34*b.m33)+(a.m44*b.m34);

  result.m41 = (a.m11*b.m41)+(a.m21*b.m42)+(a.m31*b.m43)+(a.m41*b.m44);
  result.m42 = (a.m12*b.m41)+(a.m22*b.m42)+(a.m32*b.m43)+(a.m42*b.m44);
  result.m43 = (a.m13*b.m41)+(a.m23*b.m42)+(a.m33*b.m43)+(a.m43*b.m44);
  result.m44 = (a.m14*b.m41)+(a.m24*b.m42)+(a.m34*b.m43)+(a.m44*b.m44);

  return result;
}


static CGFloat determinant2x2(CGFloat m11, CGFloat m12,
	                          CGFloat m21, CGFloat m22)
{
  return m11 * m22 - m12 * m21;
}


static CGFloat determinant3x3(CGFloat m11, CGFloat m12, CGFloat m13,
	                          CGFloat m21, CGFloat m22, CGFloat m23,
	                          CGFloat m31, CGFloat m32, CGFloat m33)
{
  return m11 * determinant2x2(m22, m23, m32, m33 )
       - m21 * determinant2x2(m12, m13, m32, m33 )
       + m31 * determinant2x2(m12, m13, m22, m23 );
}


static CGFloat determinant4x4(CATransform3D t)
{
  return t.m11 * determinant3x3(t.m22, t.m23, t.m24, t.m32, t.m33, t.m34, t.m42, t.m43, t.m44)
       - t.m21 * determinant3x3(t.m12, t.m13, t.m14, t.m32, t.m33, t.m34, t.m42, t.m43, t.m44)
       + t.m31 * determinant3x3(t.m12, t.m13, t.m14, t.m22, t.m23, t.m24, t.m42, t.m43, t.m44)
       - t.m41 * determinant3x3(t.m12, t.m13, t.m14, t.m22, t.m23, t.m24, t.m32, t.m33, t.m34);
}

CATransform3D CATransform3DInvert(CATransform3D t)
{
  const CGFloat epsilon = 0.0001; /* TODO: which value should we use? */
  CGFloat determinant = determinant4x4(t);
  if (fabs(determinant) > epsilon)
    {
      /* can be inverted */
      
      CATransform3D m;
      
      m.m11 =   determinant3x3(t.m22, t.m23, t.m24, t.m32, t.m33, t.m34, t.m42, t.m43, t.m44);
      m.m12 = - determinant3x3(t.m12, t.m13, t.m14, t.m32, t.m33, t.m34, t.m42, t.m43, t.m44);
      m.m13 =   determinant3x3(t.m12, t.m13, t.m14, t.m22, t.m23, t.m24, t.m42, t.m43, t.m44);
      m.m14 = - determinant3x3(t.m12, t.m13, t.m14, t.m22, t.m23, t.m24, t.m32, t.m33, t.m34);

      m.m21 = - determinant3x3(t.m21, t.m23, t.m24, t.m31, t.m33, t.m34, t.m41, t.m43, t.m44);
      m.m22 =   determinant3x3(t.m11, t.m13, t.m14, t.m31, t.m33, t.m34, t.m41, t.m43, t.m44);
      m.m23 = - determinant3x3(t.m11, t.m13, t.m14, t.m21, t.m23, t.m24, t.m41, t.m43, t.m44);
      m.m24 =   determinant3x3(t.m11, t.m13, t.m14, t.m21, t.m23, t.m24, t.m31, t.m33, t.m34);
  
      m.m31 =   determinant3x3(t.m21, t.m22, t.m24, t.m31, t.m32, t.m34, t.m41, t.m42, t.m44);
      m.m32 = - determinant3x3(t.m11, t.m12, t.m14, t.m31, t.m32, t.m34, t.m41, t.m42, t.m44);
      m.m33 =   determinant3x3(t.m11, t.m12, t.m14, t.m21, t.m22, t.m24, t.m41, t.m42, t.m44);
      m.m34 = - determinant3x3(t.m11, t.m12, t.m14, t.m21, t.m22, t.m24, t.m31, t.m32, t.m34);
  
      m.m41 = - determinant3x3(t.m21, t.m22, t.m23, t.m31, t.m32, t.m33, t.m41, t.m42, t.m43);
      m.m42 =   determinant3x3(t.m11, t.m12, t.m13, t.m31, t.m32, t.m33, t.m41, t.m42, t.m43);
      m.m43 = - determinant3x3(t.m11, t.m12, t.m13, t.m21, t.m22, t.m23, t.m41, t.m42, t.m43);
      m.m44 =   determinant3x3(t.m11, t.m12, t.m13, t.m21, t.m22, t.m23, t.m31, t.m32, t.m33);

      return m;
    }
  else
    {
      /* cannot be inverted */
      return t;
    }
}

@implementation NSValue (CATransform3D)

+ (NSValue *) valueWithCATransform3D:(CATransform3D)transform
{
  return [NSValue valueWithBytes:&transform objCType:@encode(CATransform3D)];
}

- (CATransform3D) CATransform3DValue
{
  CATransform3D value;
  [self getValue: &value];
  return value;
}

@end

/* code for debug output:
  for (int i = 0; i < 16; i++)
    {
      printf("%g ", ((GLfloat*)&transform)[i]);
      if (i%4 == 3) 
	printf("\n");
    }
 */

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
