/* Demo/GradientLayer.m

   Copyright (C) 2012 Free Software Foundation, Inc.

   Author: Ivan Vucica <ivan@vucica.net>
   Date: August 2012

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

#import "GradientLayer.h"

@implementation GradientLayer

- (void)drawInContext: (CGContextRef)context
{
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
#if !GNUSTEP
  CGColorRef startColor = CGColorCreateGenericRGB(0.9, 0.9, 0.8, 1.);
  CGColorRef endColor = CGColorCreateGenericRGB(1., 1., 1., 1.);

  CGFloat locations[] = { 0.0, 1.0 };

  NSArray *colors = [NSArray arrayWithObjects:(id)startColor, (id)endColor, nil];
 
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, 
      (CFArrayRef) colors, locations);
#else
  CGFloat components[8] = { 0.9, 0.9, 0.8, 1.0,  // Start color
                            1., 1., 1., 1.0 }; // End color
  size_t num_locations = 2;
  CGFloat locations[] = { 0.0, 1.0 };
  CGGradientRef gradient = CGGradientCreateWithColorComponents (colorSpace,
       components, locations, num_locations);
#endif

  CGRect rect = CGContextGetClipBoundingBox(context);
  CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
  CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
  CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

  CGColorSpaceRelease(colorSpace);
#if !GNUSTEP
  CGColorRelease(startColor);
  CGColorRelease(endColor);
#endif
  CGGradientRelease(gradient);
}
@end
