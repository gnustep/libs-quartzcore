/* CATransform3D.h

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

#if GNUSTEP
#import <CoreGraphics/CGBase.h>
#endif
typedef struct CATransform3D
{
  CGFloat m11, m12, m13, m14;
  CGFloat m21, m22, m23, m24;
  CGFloat m31, m32, m33, m34;
  CGFloat m41, m42, m43, m44;
} CATransform3D;

extern const CATransform3D CATransform3DIdentity;

BOOL CATransform3DIsIdentity(CATransform3D t);

BOOL CATransform3DEqualToTransform(CATransform3D a, CATransform3D b);

CATransform3D CATransform3DMakeTranslation(CGFloat tx, CGFloat ty, CGFloat tz);

CATransform3D CATransform3DMakeScale(CGFloat sx, CGFloat sy, CGFloat sz);

CATransform3D CATransform3DMakeRotation(CGFloat radians, CGFloat x, CGFloat y, CGFloat z);

CATransform3D CATransform3DTranslate(CATransform3D t, CGFloat tx, CGFloat ty, CGFloat tz);

CATransform3D CATransform3DScale(CATransform3D t, CGFloat sx, CGFloat sy, CGFloat sz);

CATransform3D CATransform3DRotate(CATransform3D t, CGFloat radians, CGFloat x, CGFloat y, CGFloat z);

CATransform3D CATransform3DConcat(CATransform3D a, CATransform3D b);

CATransform3D CATransform3DInvert(CATransform3D t);

@interface NSValue (CATransform3D)
+ (NSValue *) valueWithCATransform3D: (CATransform3D)transform;
- (CATransform3D) CATransform3DValue;
@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */

