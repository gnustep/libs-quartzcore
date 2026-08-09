/* CAConstraint.h

   Copyright (C) 2026 Free Software Foundation, Inc.

   Author: Todd White <todd.white@thalion.global>
   Date: August 2026

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

#import <Foundation/Foundation.h>
#import "QuartzCore/CABase.h"

@class CALayer;

/* The geometry a constraint relates.  The four X attributes come first so
   that an attribute's axis is decided by its value. */
typedef enum _CAConstraintAttribute
{
  kCAConstraintMinX = 0,
  kCAConstraintMidX = 1,
  kCAConstraintMaxX = 2,
  kCAConstraintWidth = 3,
  kCAConstraintMinY = 4,
  kCAConstraintMidY = 5,
  kCAConstraintMaxY = 6,
  kCAConstraintHeight = 7
} CAConstraintAttribute;

/* *********************************** */

/* One relationship between an attribute of the layer holding the constraint
   and an attribute of another layer, named by its -name.  The name
   "superlayer" refers to the superlayer. */
@interface CAConstraint : NSObject <NSCoding>
{
  /* property-backing ivars */
  CAConstraintAttribute _attribute;
  CAConstraintAttribute _sourceAttribute;
  NSString * _sourceName;
  CGFloat _scale;
  CGFloat _offset;
}

+ (id) constraintWithAttribute: (CAConstraintAttribute)attr
                    relativeTo: (NSString *)srcId
                     attribute: (CAConstraintAttribute)srcAttr;
+ (id) constraintWithAttribute: (CAConstraintAttribute)attr
                    relativeTo: (NSString *)srcId
                     attribute: (CAConstraintAttribute)srcAttr
                        offset: (CGFloat)c;
+ (id) constraintWithAttribute: (CAConstraintAttribute)attr
                    relativeTo: (NSString *)srcId
                     attribute: (CAConstraintAttribute)srcAttr
                         scale: (CGFloat)m
                        offset: (CGFloat)c;

- (id) initWithAttribute: (CAConstraintAttribute)attr
              relativeTo: (NSString *)srcId
               attribute: (CAConstraintAttribute)srcAttr
                   scale: (CGFloat)m
                  offset: (CGFloat)c;

@property (readonly) CAConstraintAttribute attribute;
@property (readonly) CAConstraintAttribute sourceAttribute;
@property (readonly) NSString * sourceName;
@property (readonly) CGFloat scale;
@property (readonly) CGFloat offset;

@end

/* *********************************** */

/* Lays out the sublayers of a layer under the constraints each of them
   carries.  Set it as a layer's layoutManager. */
@interface CAConstraintLayoutManager : NSObject
{
}

+ (id) layoutManager;

- (void) layoutSublayersOfLayer: (CALayer *)layer;

@end

/* vim: set cindent cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1 expandtabs shiftwidth=2 tabstop=8: */
